# frozen_string_literal: true

# Mailer for I-9 verification-related emails
class I9Mailer < ApplicationMailer
  # Sent to candidate when I-9 verification is initiated (Section 1 request)
  def section1_request(application)
    @application = application
    @candidate = application.candidate
    @job = application.job
    @organization = application.organization
    @i9_verification = application.i9_verification
    @deadline = @i9_verification&.deadline_section1

    mail(
      to: @candidate.email,
      subject: "Action Required: Complete I-9 Form - #{@job.title} at #{@organization.name}"
    )
  end

  # Sent to HR when candidate completes Section 1
  def section1_complete_notification(application)
    @application = application
    @candidate = application.candidate
    @job = application.job
    @organization = application.organization
    @i9_verification = application.i9_verification
    @deadline = @i9_verification&.deadline_section2

    # Send to hiring manager and recruiters assigned to the job
    recipients = [application.job.hiring_manager&.email].compact
    return if recipients.empty?

    mail(
      to: recipients,
      subject: "I-9 Section 1 Complete: #{@candidate.full_name} - #{@job.title}"
    )
  end

  # Sent when Section 2 is complete (confirmation to candidate)
  def section2_complete_notification(application)
    @application = application
    @candidate = application.candidate
    @job = application.job
    @organization = application.organization
    @i9_verification = application.i9_verification

    mail(
      to: @candidate.email,
      subject: "I-9 Verification Update - #{@job.title} at #{@organization.name}"
    )
  end

  # Sent to HR when Section 2 deadline is approaching
  def section2_deadline_reminder(application)
    @application = application
    @candidate = application.candidate
    @job = application.job
    @organization = application.organization
    @i9_verification = application.i9_verification
    @deadline = @i9_verification&.deadline_section2
    @days_remaining = @i9_verification&.days_until_section2_deadline

    recipients = [application.job.hiring_manager&.email].compact
    return if recipients.empty?

    mail(
      to: recipients,
      subject: "URGENT: I-9 Section 2 Deadline Approaching - #{@candidate.full_name}"
    )
  end

  # Sent when I-9 verification is complete
  def verification_complete(application)
    @application = application
    @candidate = application.candidate
    @job = application.job
    @organization = application.organization
    @i9_verification = application.i9_verification

    mail(
      to: @candidate.email,
      subject: "I-9 Verification Complete - #{@job.title} at #{@organization.name}"
    )
  end

  # Sent when I-9 verification fails
  def verification_failed(application)
    @application = application
    @candidate = application.candidate
    @job = application.job
    @organization = application.organization
    @i9_verification = application.i9_verification

    recipients = [application.job.hiring_manager&.email].compact
    return if recipients.empty?

    mail(
      to: recipients,
      subject: "I-9 Verification Failed: #{@candidate.full_name} - #{@job.title}"
    )
  end
end
