# frozen_string_literal: true

class CreateSelfScheduleService < ApplicationService
  # Create a self-scheduling invitation for a candidate
  #
  # @example
  #   result = CreateSelfScheduleService.call(
  #     interview: interview,
  #     available_slots: [
  #       { start_time: "2026-01-25T10:00:00Z", end_time: "2026-01-25T11:00:00Z" },
  #       { start_time: "2026-01-25T14:00:00Z", end_time: "2026-01-25T15:00:00Z" }
  #     ],
  #     scheduling_window_days: 7,
  #     notify_candidate: true
  #   )

  option :interview
  option :available_slots
  option :scheduling_window_days, default: -> { 7 }
  option :slot_duration_minutes, default: -> { 60 }
  option :buffer_minutes, default: -> { 15 }
  option :timezone, default: -> { "UTC" }
  option :instructions, default: -> { nil }
  option :notify_candidate, default: -> { true }

  def call
    yield validate_interview
    yield validate_slots

    self_schedule = yield create_self_schedule
    yield send_invitation(self_schedule) if notify_candidate

    Success(self_schedule)
  end

  private

  def validate_interview
    return Failure(:interview_not_found) if interview.nil?
    return Failure(:interview_already_scheduled) if interview.confirmed? || interview.completed?

    if interview.self_schedule.present?
      return Failure(:self_schedule_already_exists)
    end

    Success(interview)
  end

  def validate_slots
    if available_slots.blank? || !available_slots.is_a?(Array)
      return Failure(:no_slots_provided)
    end

    if available_slots.empty?
      return Failure(:at_least_one_slot_required)
    end

    Success(available_slots)
  end

  def create_self_schedule
    formatted_slots = available_slots.map do |slot|
      {
        "start_time" => slot[:start_time].to_s,
        "end_time" => slot[:end_time].to_s,
        "available" => true
      }
    end

    self_schedule = interview.build_self_schedule(
      scheduling_starts_at: Time.current,
      scheduling_ends_at: scheduling_window_days.days.from_now,
      available_slots: formatted_slots,
      slot_duration_minutes: slot_duration_minutes,
      buffer_minutes: buffer_minutes,
      timezone: timezone,
      instructions: instructions
    )

    if self_schedule.save
      Success(self_schedule)
    else
      Failure(self_schedule.errors.full_messages.join(", "))
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors.full_messages.join(", "))
  end

  def send_invitation(self_schedule)
    CandidateSelfScheduleMailer.invitation(self_schedule).deliver_later
    Success(true)
  rescue StandardError => e
    Rails.logger.error("Failed to send self-schedule invitation: #{e.message}")
    Success(true) # Don't fail the service for email errors
  end
end
