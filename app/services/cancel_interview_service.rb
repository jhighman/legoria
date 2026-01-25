# frozen_string_literal: true

class CancelInterviewService < ApplicationService
  # Cancel an existing interview
  #
  # @example
  #   result = CancelInterviewService.call(
  #     interview: interview,
  #     cancelled_by: current_user,
  #     reason: "Position filled"
  #   )

  option :interview
  option :cancelled_by
  option :reason, optional: true
  option :send_notifications, default: -> { true }

  def call
    yield validate_interview

    yield cancel_interview
    yield deliver_notifications if send_notifications

    Success(interview)
  end

  private

  def validate_interview
    return Failure(:interview_not_found) if interview.nil?
    return Failure(:interview_already_cancelled) if interview.cancelled?
    return Failure(:interview_already_completed) if interview.completed?
    return Failure(:interview_discarded) if interview.discarded?

    Success(interview)
  end

  def cancel_interview
    interview.cancellation_reason = reason

    if interview.cancel
      # Audit is handled by state machine callback
      Success(interview)
    else
      Failure(interview.errors.full_messages)
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors.full_messages)
  end

  def deliver_notifications
    # Send to candidate
    InterviewMailer.cancelled(interview, reason: reason).deliver_later

    # Send to all participants
    interview.interview_participants.each do |participant|
      InterviewMailer.cancelled_interviewer(interview, participant, reason: reason).deliver_later
    end

    Success(true)
  rescue StandardError => e
    Rails.logger.error("Failed to send cancellation notifications: #{e.message}")
    Success(true)
  end
end
