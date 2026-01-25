# frozen_string_literal: true

class WorkAuthorizationExpirationJob < ApplicationJob
  queue_as :default

  # Run daily to check for work authorization expirations
  def perform
    send_90_day_warnings
    send_30_day_warnings
    mark_expired_authorizations
  end

  private

  def send_90_day_warnings
    # First-time 90-day warning
    WorkAuthorization.unscoped
      .where(indefinite: false)
      .where(reverification_reminder_sent: false)
      .where("valid_until <= ?", 90.days.from_now.to_date)
      .where("valid_until > ?", Date.current)
      .find_each do |auth|
        Current.organization = auth.organization

        WorkAuthorizationMailer.expiration_warning(auth, 90).deliver_later

        auth.update!(
          reverification_reminder_sent: true,
          reverification_reminder_sent_at: Time.current
        )
      ensure
        Current.reset
      end
  end

  def send_30_day_warnings
    # 30-day warning (re-send regardless of previous reminder)
    WorkAuthorization.unscoped
      .where(indefinite: false)
      .where("valid_until <= ?", 30.days.from_now.to_date)
      .where("valid_until > ?", Date.current)
      .find_each do |auth|
        Current.organization = auth.organization

        WorkAuthorizationMailer.expiration_warning(auth, 30).deliver_later
      ensure
        Current.reset
      end
  end

  def mark_expired_authorizations
    # Mark expired and trigger I-9 expiration if applicable
    WorkAuthorization.unscoped
      .where(indefinite: false)
      .where("valid_until < ?", Date.current)
      .find_each do |auth|
        Current.organization = auth.organization

        # Expire the linked I-9 verification if it's currently verified
        if auth.i9_verification&.status == "verified"
          auth.i9_verification.expire!

          AuditLog.log(
            action: "work_authorization.expired",
            auditable: auth,
            metadata: {
              work_authorization_id: auth.id,
              candidate_name: auth.candidate&.full_name,
              authorization_type: auth.authorization_type,
              valid_until: auth.valid_until.iso8601
            }
          )
        end
      ensure
        Current.reset
      end
  end
end
