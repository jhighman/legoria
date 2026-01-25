# frozen_string_literal: true

class AdverseAction < ApplicationRecord
  include OrganizationScoped
  include Auditable

  # Status constants
  STATUSES = %w[draft pre_adverse_sent waiting_period final_sent completed cancelled].freeze
  ACTION_TYPES = %w[rejection offer_withdrawal termination].freeze
  REASON_CATEGORIES = %w[background_check credential_verification reference_check other].freeze
  DELIVERY_METHODS = %w[email mail both].freeze

  # FCRA default waiting period (business days)
  DEFAULT_WAITING_PERIOD_DAYS = 5

  # Associations
  belongs_to :application
  belongs_to :initiated_by, class_name: "User"

  # Delegations
  delegate :candidate, :job, to: :application

  # Validations
  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :reason_category, presence: true, inclusion: { in: REASON_CATEGORIES }
  validates :waiting_period_days, numericality: { greater_than: 0 }, allow_nil: true
  validates :pre_adverse_delivery_method, inclusion: { in: DELIVERY_METHODS }, allow_nil: true
  validates :final_adverse_delivery_method, inclusion: { in: DELIVERY_METHODS }, allow_nil: true

  validate :waiting_period_ends_after_pre_adverse

  # Callbacks
  before_validation :set_default_waiting_period, on: :create

  # Scopes
  scope :drafts, -> { where(status: "draft") }
  scope :in_progress, -> { where(status: %w[pre_adverse_sent waiting_period]) }
  scope :completed, -> { where(status: "completed") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :active, -> { where(status: %w[draft pre_adverse_sent waiting_period final_sent]) }
  scope :waiting_period_ended, -> { where(status: "waiting_period").where("waiting_period_ends_at <= ?", Time.current) }
  scope :with_disputes, -> { where(candidate_disputed: true) }

  # Status helpers
  def draft?
    status == "draft"
  end

  def pre_adverse_sent?
    status == "pre_adverse_sent"
  end

  def waiting_period?
    status == "waiting_period"
  end

  def final_sent?
    status == "final_sent"
  end

  def completed?
    status == "completed"
  end

  def cancelled?
    status == "cancelled"
  end

  def can_send_pre_adverse?
    draft?
  end

  def can_send_final?
    waiting_period? && waiting_period_elapsed?
  end

  def waiting_period_elapsed?
    waiting_period_ends_at.present? && waiting_period_ends_at <= Time.current
  end

  # Workflow actions
  def send_pre_adverse!(content:, delivery_method: "email")
    raise StandardError, "Cannot send - not in draft status" unless draft?

    update!(
      status: "pre_adverse_sent",
      pre_adverse_sent_at: Time.current,
      pre_adverse_content: content,
      pre_adverse_delivery_method: delivery_method
    )

    # Automatically transition to waiting period
    start_waiting_period!
  end

  def start_waiting_period!
    raise StandardError, "Pre-adverse action not sent" unless pre_adverse_sent?

    update!(
      status: "waiting_period",
      waiting_period_ends_at: calculate_waiting_period_end
    )
  end

  def record_dispute!(details)
    raise StandardError, "Cannot dispute - not in waiting period" unless waiting_period?

    update!(
      candidate_disputed: true,
      dispute_details: details,
      dispute_received_at: Time.current
    )
  end

  def send_final_adverse!(content:, delivery_method: "email")
    raise StandardError, "Cannot send - waiting period not elapsed" unless can_send_final?

    transaction do
      update!(
        status: "final_sent",
        final_adverse_sent_at: Time.current,
        final_adverse_content: content,
        final_adverse_delivery_method: delivery_method
      )

      # Reject the application
      application.reject! if application.can_reject?
    end
  end

  def complete!
    raise StandardError, "Cannot complete - final notice not sent" unless final_sent?

    update!(status: "completed")
  end

  def cancel!(reason = nil)
    raise StandardError, "Cannot cancel - already completed" if completed?

    update!(
      status: "cancelled",
      reason_details: [reason_details, "Cancelled: #{reason}"].compact.join("\n\n")
    )
  end

  # Display helpers
  def status_label
    case status
    when "pre_adverse_sent" then "Pre-Adverse Sent"
    when "waiting_period" then "Waiting Period"
    when "final_sent" then "Final Notice Sent"
    else status.titleize
    end
  end

  def status_color
    case status
    when "draft" then "gray"
    when "pre_adverse_sent" then "yellow"
    when "waiting_period" then "orange"
    when "final_sent" then "red"
    when "completed" then "red"
    when "cancelled" then "gray"
    else "gray"
    end
  end

  def action_type_label
    action_type.titleize.gsub("_", " ")
  end

  def reason_category_label
    reason_category.titleize.gsub("_", " ")
  end

  def days_in_waiting_period
    return nil unless pre_adverse_sent_at

    (Time.current.to_date - pre_adverse_sent_at.to_date).to_i
  end

  def days_remaining_in_waiting
    return nil unless waiting_period? && waiting_period_ends_at

    remaining = (waiting_period_ends_at.to_date - Time.current.to_date).to_i
    [remaining, 0].max
  end

  private

  def set_default_waiting_period
    self.waiting_period_days ||= DEFAULT_WAITING_PERIOD_DAYS
  end

  def calculate_waiting_period_end
    # Calculate business days
    end_date = pre_adverse_sent_at.to_date
    days_added = 0

    while days_added < waiting_period_days
      end_date += 1.day
      days_added += 1 unless end_date.saturday? || end_date.sunday?
    end

    end_date.end_of_day
  end

  def waiting_period_ends_after_pre_adverse
    return unless waiting_period_ends_at && pre_adverse_sent_at

    if waiting_period_ends_at <= pre_adverse_sent_at
      errors.add(:waiting_period_ends_at, "must be after pre-adverse action sent date")
    end
  end
end
