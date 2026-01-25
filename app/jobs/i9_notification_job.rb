# frozen_string_literal: true

class I9NotificationJob < ApplicationJob
  queue_as :default

  def perform(application_id, notification_type)
    application = Application.unscoped.find_by(id: application_id)
    return unless application

    # Set organization context for mailer
    Current.organization = application.organization

    case notification_type
    when "section1_request"
      I9Mailer.section1_request(application).deliver_later
    when "section1_complete"
      I9Mailer.section1_complete_notification(application).deliver_later
    when "section2_complete"
      I9Mailer.section2_complete_notification(application).deliver_later
    when "section2_reminder"
      I9Mailer.section2_deadline_reminder(application).deliver_later
    when "verification_complete"
      I9Mailer.verification_complete(application).deliver_later
    when "verification_failed"
      I9Mailer.verification_failed(application).deliver_later
    else
      Rails.logger.warn "Unknown I-9 notification type: #{notification_type}"
    end
  ensure
    Current.reset
  end
end
