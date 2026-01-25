# frozen_string_literal: true

# Mailer for work authorization-related emails
class WorkAuthorizationMailer < ApplicationMailer
  # Sent when work authorization is expiring
  def expiration_warning(work_authorization, days_until_expiration)
    @work_authorization = work_authorization
    @candidate = work_authorization.candidate
    @organization = work_authorization.organization
    @days_until_expiration = days_until_expiration
    @expiration_date = work_authorization.valid_until

    # Find associated applications for context
    @applications = @candidate.applications.where(organization: @organization).active

    # Determine urgency for subject line
    urgency = case days_until_expiration
              when 0..7 then "URGENT: "
              when 8..30 then "Action Required: "
              else ""
              end

    # Send to HR and the candidate
    hr_recipients = User.unscoped
                        .where(organization: @organization)
                        .joins(:roles)
                        .where(roles: { name: %w[admin recruiter] })
                        .pluck(:email)
                        .compact

    mail(
      to: hr_recipients.presence || [@candidate.email],
      cc: hr_recipients.present? ? @candidate.email : nil,
      subject: "#{urgency}Work Authorization Expiring: #{@candidate.full_name}"
    )
  end

  # Sent when reverification is required
  def reverification_required(work_authorization)
    @work_authorization = work_authorization
    @candidate = work_authorization.candidate
    @organization = work_authorization.organization
    @i9_verification = work_authorization.i9_verification

    mail(
      to: @candidate.email,
      subject: "Work Authorization Reverification Required"
    )
  end

  # Sent when work authorization has expired
  def authorization_expired(work_authorization)
    @work_authorization = work_authorization
    @candidate = work_authorization.candidate
    @organization = work_authorization.organization

    # Send to HR
    hr_recipients = User.unscoped
                        .where(organization: @organization)
                        .joins(:roles)
                        .where(roles: { name: %w[admin recruiter] })
                        .pluck(:email)
                        .compact

    return if hr_recipients.empty?

    mail(
      to: hr_recipients,
      subject: "Work Authorization Expired: #{@candidate.full_name}"
    )
  end
end
