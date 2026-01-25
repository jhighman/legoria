# frozen_string_literal: true

# Mailer for job application-related emails
class JobApplicationMailer < ApplicationMailer
  # Sent when a candidate submits an application
  def application_received(application)
    @application = application
    @candidate = application.candidate
    @job = application.job
    @organization = application.organization
    @status_url = application_status_check_url(application.tracking_token)

    mail(
      to: @candidate.email,
      subject: "Application Received - #{@job.title} at #{@organization.name}"
    )
  end

  # Sent when application status changes
  def status_update(application)
    @application = application
    @candidate = application.candidate
    @job = application.job
    @organization = application.organization
    @status_url = application_status_check_url(application.tracking_token)

    mail(
      to: @candidate.email,
      subject: "Application Update - #{@job.title} at #{@organization.name}"
    )
  end

  # Sent when candidate is moved to interview stage
  def interview_scheduled(application, interview_details = {})
    @application = application
    @candidate = application.candidate
    @job = application.job
    @organization = application.organization
    @interview_details = interview_details
    @status_url = application_status_check_url(application.tracking_token)

    mail(
      to: @candidate.email,
      subject: "Interview Invitation - #{@job.title} at #{@organization.name}"
    )
  end

  # Sent when candidate receives an offer
  def offer_extended(application)
    @application = application
    @candidate = application.candidate
    @job = application.job
    @organization = application.organization
    @status_url = application_status_check_url(application.tracking_token)

    mail(
      to: @candidate.email,
      subject: "Job Offer - #{@job.title} at #{@organization.name}"
    )
  end

  # Sent when application is rejected
  def rejection_notice(application)
    @application = application
    @candidate = application.candidate
    @job = application.job
    @organization = application.organization

    mail(
      to: @candidate.email,
      subject: "Application Update - #{@job.title} at #{@organization.name}"
    )
  end
end
