# frozen_string_literal: true

class RescheduleInterviewService < ApplicationService
  # Reschedule an existing interview
  #
  # @example
  #   result = RescheduleInterviewService.call(
  #     interview: interview,
  #     scheduled_at: new_time,
  #     rescheduled_by: current_user,
  #     reason: "Interviewer availability changed"
  #   )

  option :interview
  option :scheduled_at
  option :rescheduled_by
  option :duration_minutes, optional: true
  option :location, optional: true
  option :video_meeting_url, optional: true
  option :reason, optional: true
  option :send_notifications, default: -> { true }

  def call
    yield validate_interview
    yield validate_new_time

    original_time = interview.scheduled_at
    yield update_interview
    yield deliver_notifications(original_time) if send_notifications

    Success(interview)
  end

  private

  def validate_interview
    return Failure(:interview_not_found) if interview.nil?
    return Failure(:interview_not_active) unless interview.active?
    return Failure(:interview_discarded) if interview.discarded?

    Success(interview)
  end

  def validate_new_time
    return Failure(:scheduled_at_required) if scheduled_at.blank?
    return Failure(:must_be_in_future) if scheduled_at <= Time.current
    return Failure(:same_time) if scheduled_at == interview.scheduled_at

    Success(true)
  end

  def update_interview
    attributes = { scheduled_at: scheduled_at }
    attributes[:duration_minutes] = duration_minutes if duration_minutes.present?
    attributes[:location] = location if location.present?
    attributes[:video_meeting_url] = video_meeting_url if video_meeting_url.present?

    if interview.update(attributes)
      # Log the reschedule in audit
      interview.audit!(
        "interview.rescheduled",
        metadata: {
          rescheduled_by: rescheduled_by&.display_name,
          reason: reason,
          new_time: scheduled_at.iso8601
        },
        recorded_changes: { scheduled_at: [interview.scheduled_at_before_last_save, scheduled_at] }
      )

      Success(interview)
    else
      Failure(interview.errors.full_messages)
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors.full_messages)
  end

  def deliver_notifications(original_time)
    # Send to candidate
    InterviewMailer.rescheduled(interview, original_time: original_time, reason: reason).deliver_later

    # Send to all participants
    interview.interview_participants.each do |participant|
      InterviewMailer.rescheduled_interviewer(interview, participant, original_time: original_time, reason: reason).deliver_later
    end

    Success(true)
  rescue StandardError => e
    Rails.logger.error("Failed to send reschedule notifications: #{e.message}")
    Success(true)
  end
end
