# frozen_string_literal: true

# SA-11: Integration - Outbound webhook configuration
# Allows organizations to receive real-time notifications of events
class Webhook < ApplicationRecord
  include OrganizationScoped
  include Discardable

  # Associations
  belongs_to :created_by, class_name: "User"

  has_many :webhook_deliveries, dependent: :destroy

  # Encryption
  encrypts :secret

  # Available event types
  EVENT_TYPES = %w[
    application.created
    application.updated
    application.stage_changed
    application.hired
    application.rejected
    candidate.created
    candidate.updated
    interview.scheduled
    interview.completed
    interview.cancelled
    offer.created
    offer.sent
    offer.accepted
    offer.declined
    background_check.completed
    background_check.failed
  ].freeze

  STATUSES = %w[active failing disabled].freeze

  # Validations
  validates :name, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :status, inclusion: { in: STATUSES }

  validate :validate_events

  # Callbacks
  before_create :generate_secret

  # Scopes
  scope :active, -> { where(active: true, status: "active") }
  scope :for_event, ->(event_type) {
    # SQLite JSON array containment check
    where("json_extract(events, '$') LIKE ?", "%#{event_type}%")
  }

  # Instance methods
  def active_for_delivery?
    active? && status == "active"
  end

  def subscribes_to?(event_type)
    events&.include?(event_type)
  end

  def pause!
    update!(status: "failing")
  end

  def resume!
    update!(status: "active", consecutive_failures: 0)
  end

  def disable!
    update!(status: "disabled", active: false)
  end

  def regenerate_secret!
    generate_secret
    save!
  end

  def compute_signature(payload)
    OpenSSL::HMAC.hexdigest("SHA256", secret.to_s, payload)
  end

  def record_delivery(success:, response_code: nil, error_message: nil)
    if success
      increment!(:success_count)
      update!(
        last_triggered_at: Time.current,
        last_success_at: Time.current,
        consecutive_failures: 0
      )
    else
      increment!(:failure_count)
      increment!(:consecutive_failures)
      update!(last_failure_at: Time.current)
      check_failure_threshold!
    end
  end

  private

  def generate_secret
    self.secret = SecureRandom.hex(32)
  end

  def validate_events
    return if events.blank?

    invalid_types = events - EVENT_TYPES
    return if invalid_types.empty?

    errors.add(:events, "contains invalid types: #{invalid_types.join(', ')}")
  end

  def check_failure_threshold!
    # Auto-disable after 10 consecutive failures
    return unless consecutive_failures >= 10

    disable!
  end
end
