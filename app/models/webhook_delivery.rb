# frozen_string_literal: true

# SA-11: Integration - Webhook delivery tracking
# Records each attempt to deliver a webhook, including retries
class WebhookDelivery < ApplicationRecord
  include OrganizationScoped

  # Associations
  belongs_to :webhook

  # Status constants
  STATUSES = %w[pending sending success failed retrying].freeze

  # Validations
  validates :event_type, presence: true
  validates :event_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :attempt_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :failed, -> { where(status: "failed") }
  scope :successful, -> { where(status: "success") }
  scope :retrying, -> { where(status: "retrying") }
  scope :needs_retry, -> { retrying.where("next_retry_at <= ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_event_type, ->(type) { where(event_type: type) }

  # Maximum retry attempts
  MAX_ATTEMPTS = 5

  # Exponential backoff schedule (in seconds)
  RETRY_DELAYS = [60, 300, 900, 3600, 14400].freeze # 1m, 5m, 15m, 1h, 4h

  # Class methods
  def self.create_for_event(webhook:, event_type:, payload:)
    create!(
      organization: webhook.organization,
      webhook: webhook,
      event_type: event_type,
      event_id: SecureRandom.uuid,
      payload: payload,
      status: "pending",
      attempt_count: 0
    )
  end

  # Instance methods
  def pending?
    status == "pending"
  end

  def delivered?
    status == "success"
  end

  def failed?
    status == "failed"
  end

  def retrying?
    status == "retrying"
  end

  def can_retry?
    attempt_count < max_attempts && !delivered?
  end

  def mark_sending!
    update!(status: "sending")
  end

  def mark_delivered!(response_status:, response_body: nil, response_time_ms: nil)
    update!(
      status: "success",
      response_status: response_status,
      response_body: truncate_response(response_body),
      delivered_at: Time.current,
      response_time_ms: response_time_ms
    )
    webhook.record_delivery(success: true, response_code: response_status)
  end

  def mark_failed!(response_status: nil, response_body: nil, error_message: nil, error_type: nil, response_time_ms: nil)
    increment!(:attempt_count)

    if can_retry?
      schedule_retry!
    else
      update!(
        status: "failed",
        response_status: response_status,
        response_body: truncate_response(response_body),
        error_message: error_message,
        error_type: error_type,
        response_time_ms: response_time_ms
      )
      webhook.record_delivery(success: false, response_code: response_status, error_message: error_message)
    end
  end

  def schedule_retry!
    delay = RETRY_DELAYS[[attempt_count - 1, RETRY_DELAYS.length - 1].min]
    update!(
      status: "retrying",
      next_retry_at: delay.seconds.from_now
    )
  end

  def retry!
    return unless can_retry?

    # Reset for next attempt
    update!(status: "pending")
    # Trigger delivery (would be handled by a background job)
  end

  private

  def truncate_response(body)
    return nil if body.nil?

    body.to_s.truncate(10_000)
  end
end
