# frozen_string_literal: true

class DeletionRequest < ApplicationRecord
  include OrganizationScoped

  # Status constants
  STATUSES = %w[pending in_progress completed rejected].freeze
  REQUEST_SOURCES = %w[candidate_portal email verbal legal].freeze
  VERIFICATION_METHODS = %w[email_confirmation id_check phone].freeze

  # Associations
  belongs_to :candidate
  belongs_to :processed_by, class_name: "User", optional: true

  # Validations
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :request_source, presence: true, inclusion: { in: REQUEST_SOURCES }
  validates :requested_at, presence: true
  validates :verification_method, inclusion: { in: VERIFICATION_METHODS }, allow_nil: true

  validates :rejection_reason, presence: true, if: :rejected?

  validate :legal_hold_prevents_completion

  # Callbacks
  before_validation :set_requested_at, on: :create

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :completed, -> { where(status: "completed") }
  scope :rejected, -> { where(status: "rejected") }
  scope :active, -> { where(status: %w[pending in_progress]) }
  scope :on_legal_hold, -> { where(legal_hold: true) }
  scope :recent, -> { order(requested_at: :desc) }

  # Status helpers
  def pending?
    status == "pending"
  end

  def in_progress?
    status == "in_progress"
  end

  def completed?
    status == "completed"
  end

  def rejected?
    status == "rejected"
  end

  def can_process?
    (pending? || in_progress?) && identity_verified? && !legal_hold?
  end

  # Verification
  def verify_identity!(method)
    update!(
      identity_verified: true,
      verification_method: method,
      verified_at: Time.current
    )
  end

  # Workflow actions
  def start_processing!(user)
    raise StandardError, "Cannot process - not verified" unless identity_verified?
    raise StandardError, "Cannot process - on legal hold" if legal_hold?

    update!(
      status: "in_progress",
      processed_by: user,
      processed_at: Time.current
    )
  end

  def complete!(deleted_data:, retained_data: nil)
    raise StandardError, "Cannot complete - on legal hold" if legal_hold?

    update!(
      status: "completed",
      data_deleted: deleted_data,
      data_retained: retained_data,
      completed_at: Time.current
    )
  end

  def reject!(reason, user = nil)
    update!(
      status: "rejected",
      rejection_reason: reason,
      processed_by: user,
      processed_at: Time.current
    )
  end

  # Legal hold
  def place_legal_hold!(reason)
    update!(
      legal_hold: true,
      legal_hold_reason: reason
    )
  end

  def remove_legal_hold!
    update!(
      legal_hold: false,
      legal_hold_reason: nil
    )
  end

  # Display helpers
  def status_label
    status.titleize.gsub("_", " ")
  end

  def status_color
    case status
    when "pending" then "yellow"
    when "in_progress" then "blue"
    when "completed" then "green"
    when "rejected" then "red"
    else "gray"
    end
  end

  def request_source_label
    request_source.titleize.gsub("_", " ")
  end

  def days_since_request
    (Date.current - requested_at.to_date).to_i
  end

  # GDPR requires processing within 30 days
  def past_deadline?
    days_since_request > 30 && !completed? && !rejected?
  end

  def deadline_date
    requested_at.to_date + 30.days
  end

  private

  def set_requested_at
    self.requested_at ||= Time.current
  end

  def legal_hold_prevents_completion
    return unless legal_hold? && status_changed? && completed?

    errors.add(:status, "cannot be completed while on legal hold")
  end
end
