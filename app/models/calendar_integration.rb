# frozen_string_literal: true

class CalendarIntegration < ApplicationRecord
  # Providers
  PROVIDERS = %w[google outlook apple].freeze

  # Associations
  belongs_to :user

  # Encrypt OAuth tokens
  encrypts :access_token_encrypted
  encrypts :refresh_token_encrypted

  # Validations
  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :provider, uniqueness: { scope: :user_id, message: "integration already exists" }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_provider, ->(provider) { where(provider: provider) if provider.present? }
  scope :expiring_soon, -> { where("token_expires_at < ?", 1.hour.from_now) }
  scope :expired, -> { where("token_expires_at < ?", Time.current) }

  # Provider helpers
  def google?
    provider == "google"
  end

  def outlook?
    provider == "outlook"
  end

  def apple?
    provider == "apple"
  end

  # Token management
  def access_token
    access_token_encrypted
  end

  def access_token=(value)
    self.access_token_encrypted = value
  end

  def refresh_token
    refresh_token_encrypted
  end

  def refresh_token=(value)
    self.refresh_token_encrypted = value
  end

  def token_expired?
    token_expires_at.present? && token_expires_at < Time.current
  end

  def token_expiring_soon?
    token_expires_at.present? && token_expires_at < 5.minutes.from_now
  end

  def needs_refresh?
    token_expired? || token_expiring_soon?
  end

  # Activation
  def activate!
    update!(active: true, sync_error: nil)
  end

  def deactivate!
    update!(active: false)
  end

  def deactivate_with_error!(error_message)
    update!(active: false, sync_error: error_message)
  end

  # Sync tracking
  def mark_synced!
    update!(last_synced_at: Time.current, sync_error: nil)
  end

  def mark_sync_error!(error_message)
    update!(sync_error: error_message)
  end

  def recently_synced?(within: 15.minutes)
    last_synced_at.present? && last_synced_at > within.ago
  end

  # Status helpers
  def healthy?
    active? && !token_expired? && sync_error.blank?
  end

  def status
    return "error" if sync_error.present?
    return "inactive" unless active?
    return "expired" if token_expired?

    "connected"
  end

  def status_label
    case status
    when "connected" then "Connected"
    when "inactive" then "Inactive"
    when "expired" then "Token Expired"
    when "error" then "Sync Error"
    else "Unknown"
    end
  end

  def status_color
    case status
    when "connected" then "green"
    when "inactive" then "gray"
    when "expired" then "orange"
    when "error" then "red"
    else "gray"
    end
  end

  # Provider display
  def provider_label
    case provider
    when "google" then "Google Calendar"
    when "outlook" then "Microsoft Outlook"
    when "apple" then "Apple Calendar"
    else provider.titleize
    end
  end

  def provider_icon
    case provider
    when "google" then "google"
    when "outlook" then "microsoft"
    when "apple" then "apple"
    else "calendar"
    end
  end
end
