# frozen_string_literal: true

class ScheduleInterviewService < ApplicationService
  # Schedule a new interview for an application
  #
  # @example
  #   result = ScheduleInterviewService.call(
  #     application: application,
  #     interview_type: "video",
  #     scheduled_at: 2.days.from_now,
  #     duration_minutes: 60,
  #     scheduled_by: current_user,
  #     participants: [{ user: interviewer, role: "lead" }]
  #   )

  option :application
  option :interview_type
  option :scheduled_at
  option :scheduled_by
  option :title, optional: true
  option :duration_minutes, optional: true
  option :timezone, optional: true
  option :location, optional: true
  option :video_meeting_url, optional: true
  option :instructions, optional: true
  option :participants, default: -> { [] }
  option :send_notifications, default: -> { true }

  def call
    yield validate_application
    yield validate_participants

    interview = yield create_interview
    yield add_participants(interview)
    yield deliver_notifications(interview) if send_notifications

    Success(interview)
  end

  private

  def validate_application
    return Failure(:application_not_found) if application.nil?
    return Failure(:application_not_active) unless application.active?
    return Failure(:application_discarded) if application.discarded?

    Success(application)
  end

  def validate_participants
    return Success(true) if participants.empty?

    participants.each do |p|
      user = p[:user] || p["user"]
      return Failure(:participant_not_found) if user.nil?
      return Failure(:participant_wrong_organization) if user.organization_id != application.organization_id
    end

    Success(true)
  end

  def create_interview
    interview = Interview.new(
      organization: application.organization,
      application: application,
      job: application.job,
      scheduled_by: scheduled_by,
      interview_type: interview_type,
      scheduled_at: scheduled_at,
      duration_minutes: duration_minutes || Interview::DEFAULT_DURATIONS[interview_type] || 60,
      timezone: timezone || Current.organization&.timezone || "UTC",
      title: title,
      location: location,
      video_meeting_url: video_meeting_url,
      instructions: instructions
    )

    if interview.save
      Success(interview)
    else
      Failure(interview.errors.full_messages)
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors.full_messages)
  end

  def add_participants(interview)
    participants.each do |p|
      user = p[:user] || p["user"]
      role = p[:role] || p["role"] || "interviewer"

      participant = interview.interview_participants.build(user: user, role: role)
      return Failure(participant.errors.full_messages) unless participant.save
    end

    # Add the scheduler as lead if no lead assigned
    unless interview.lead_interviewer
      interview.add_participant(scheduled_by, role: "lead")
    end

    Success(interview.reload)
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors.full_messages)
  end

  def deliver_notifications(interview)
    # Send to candidate
    InterviewMailer.scheduled_candidate(interview).deliver_later

    # Send to each interviewer
    interview.interview_participants.each do |participant|
      InterviewMailer.scheduled_interviewer(interview, participant).deliver_later
    end

    Success(true)
  rescue StandardError => e
    # Log but don't fail the operation for notification errors
    Rails.logger.error("Failed to send interview notifications: #{e.message}")
    Success(true)
  end
end
