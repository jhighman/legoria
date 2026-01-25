# frozen_string_literal: true

# Mailer for interview-related emails
class InterviewMailer < ApplicationMailer
  # Sent to candidate when interview is scheduled
  def scheduled_candidate(interview)
    @interview = interview
    @application = interview.application
    @candidate = @application.candidate
    @job = interview.job
    @organization = interview.organization
    @status_url = application_status_check_url(@application.tracking_token)

    mail(
      to: @candidate.email,
      subject: "Interview Scheduled - #{@job.title} at #{@organization.name}"
    )
  end

  # Sent to interviewer when they are assigned to an interview
  def scheduled_interviewer(interview, participant)
    @interview = interview
    @participant = participant
    @user = participant.user
    @application = interview.application
    @candidate = @application.candidate
    @job = interview.job
    @organization = interview.organization

    mail(
      to: @user.email,
      subject: "Interview Assignment - #{@candidate.full_name} for #{@job.title}"
    )
  end

  # Reminder to candidate 24 hours before
  def reminder_candidate(interview)
    @interview = interview
    @application = interview.application
    @candidate = @application.candidate
    @job = interview.job
    @organization = interview.organization
    @status_url = application_status_check_url(@application.tracking_token)

    mail(
      to: @candidate.email,
      subject: "Interview Reminder - Tomorrow at #{@interview.scheduled_at_formatted(format: :time)}"
    )
  end

  # Reminder to interviewer 1 hour before
  def reminder_interviewer(interview, participant)
    @interview = interview
    @participant = participant
    @user = participant.user
    @application = interview.application
    @candidate = @application.candidate
    @job = interview.job
    @organization = interview.organization

    mail(
      to: @user.email,
      subject: "Interview in 1 Hour - #{@candidate.full_name}"
    )
  end

  # Sent to candidate when interview is rescheduled
  def rescheduled(interview, original_time:, reason: nil)
    @interview = interview
    @original_time = original_time
    @reason = reason
    @application = interview.application
    @candidate = @application.candidate
    @job = interview.job
    @organization = interview.organization
    @status_url = application_status_check_url(@application.tracking_token)

    mail(
      to: @candidate.email,
      subject: "Interview Rescheduled - #{@job.title} at #{@organization.name}"
    )
  end

  # Sent to interviewer when interview is rescheduled
  def rescheduled_interviewer(interview, participant, original_time:, reason: nil)
    @interview = interview
    @participant = participant
    @original_time = original_time
    @reason = reason
    @user = participant.user
    @application = interview.application
    @candidate = @application.candidate
    @job = interview.job
    @organization = interview.organization

    mail(
      to: @user.email,
      subject: "Interview Rescheduled - #{@candidate.full_name} for #{@job.title}"
    )
  end

  # Sent to candidate when interview is cancelled
  def cancelled(interview, reason: nil)
    @interview = interview
    @reason = reason
    @application = interview.application
    @candidate = @application.candidate
    @job = interview.job
    @organization = interview.organization
    @status_url = application_status_check_url(@application.tracking_token)

    mail(
      to: @candidate.email,
      subject: "Interview Cancelled - #{@job.title} at #{@organization.name}"
    )
  end

  # Sent to interviewer when interview is cancelled
  def cancelled_interviewer(interview, participant, reason: nil)
    @interview = interview
    @participant = participant
    @reason = reason
    @user = participant.user
    @application = interview.application
    @candidate = @application.candidate
    @job = interview.job

    mail(
      to: @user.email,
      subject: "Interview Cancelled - #{@candidate.full_name}"
    )
  end

  # Sent to interviewer requesting feedback after interview completion
  def feedback_request(interview, participant)
    @interview = interview
    @participant = participant
    @user = participant.user
    @application = interview.application
    @candidate = @application.candidate
    @job = interview.job
    @organization = interview.organization

    mail(
      to: @user.email,
      subject: "Feedback Requested - #{@candidate.full_name} Interview"
    )
  end
end
