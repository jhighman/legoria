# frozen_string_literal: true

# SA-11: Integration - External service configuration
# Manages connections to job boards, HRIS systems, background check providers, etc.
class Integration < ApplicationRecord
  include OrganizationScoped
  include Discardable

  # Associations
  belongs_to :created_by, class_name: "User"

  has_many :integration_logs, dependent: :destroy
  has_many :job_board_postings, dependent: :nullify
  has_many :background_checks, dependent: :restrict_with_error
  has_many :hris_exports, dependent: :restrict_with_error

  # Encryption
  encrypts :api_key
  encrypts :api_secret
  encrypts :access_token
  encrypts :refresh_token

  # Enums
  INTEGRATION_TYPES = %w[job_board hris background_check calendar assessment].freeze
  PROVIDERS = {
    job_board: %w[indeed linkedin ziprecruiter glassdoor],
    hris: %w[workday bamboo_hr adp paychex],
    background_check: %w[checkr sterling goodhire hireright ledgoria],
    calendar: %w[google_calendar outlook_calendar],
    assessment: %w[codility hackerrank criteria]
  }.freeze
  STATUSES = %w[pending active error disabled].freeze
  SYNC_FREQUENCIES = %w[realtime hourly daily weekly manual].freeze

  # Validations
  validates :integration_type, presence: true, inclusion: { in: INTEGRATION_TYPES }
  validates :provider, presence: true
  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :sync_frequency, inclusion: { in: SYNC_FREQUENCIES }, allow_nil: true

  validate :validate_provider_for_type

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :by_type, ->(type) { where(integration_type: type) }
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :auto_sync_enabled, -> { where(auto_sync: true) }
  scope :needs_token_refresh, -> { where("token_expires_at < ?", 5.minutes.from_now) }

  # Instance methods
  def active?
    status == "active"
  end

  def pending?
    status == "pending"
  end

  def disabled?
    status == "disabled"
  end

  def error?
    status == "error"
  end

  def token_expired?
    return false unless token_expires_at

    token_expires_at < Time.current
  end

  def token_expiring_soon?
    return false unless token_expires_at

    token_expires_at < 5.minutes.from_now
  end

  def refresh_token!
    return Success(:no_refresh_needed) unless token_expiring_soon?

    # Subclasses or services handle the actual refresh
    Success(:refreshed)
  end

  def activate!
    update!(status: "active", last_sync_at: Time.current)
  end

  def deactivate!
    update!(status: "disabled")
  end

  def mark_error!(message)
    update!(status: "error", last_error: message)
  end

  def log_sync(action, direction: "outbound", resource_type: nil, resource_id: nil, success: true, error_message: nil)
    integration_logs.create!(
      organization: organization,
      action: action,
      direction: direction,
      status: success ? "success" : "failed",
      resource_type: resource_type,
      resource_id: resource_id,
      error_message: error_message,
      started_at: Time.current,
      completed_at: Time.current
    )
  end

  private

  def validate_provider_for_type
    return if integration_type.blank? || provider.blank?

    valid_providers = PROVIDERS[integration_type.to_sym] || []
    return if valid_providers.include?(provider)

    errors.add(:provider, "is not valid for #{integration_type}")
  end
end
