# frozen_string_literal: true

# SA-09/SA-11: Compliance & Integration - Background check workflow
# Tracks background check requests, consent, and results from external providers
class BackgroundCheck < ApplicationRecord
  include OrganizationScoped

  # Associations
  belongs_to :application
  belongs_to :candidate
  belongs_to :integration
  belongs_to :requested_by, class_name: "User"
  belongs_to :adverse_action, optional: true

  # Status workflow
  STATUSES = %w[
    pending
    consent_required
    consent_given
    in_progress
    review_required
    completed
    cancelled
    expired
  ].freeze

  # Result types
  RESULTS = %w[clear consider adverse incomplete].freeze

  # Check types
  CHECK_TYPES = %w[
    criminal
    employment
    education
    credit
    drug_screen
    identity
    driving
    professional_license
  ].freeze

  # Consent methods
  CONSENT_METHODS = %w[email portal in_person].freeze

  # Validations
  validates :status, inclusion: { in: STATUSES }
  validates :result, inclusion: { in: RESULTS }, allow_nil: true
  validates :consent_method, inclusion: { in: CONSENT_METHODS }, allow_nil: true

  validate :validate_check_types

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :awaiting_consent, -> { where(status: "consent_required") }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :needs_review, -> { where(status: "review_required") }
  scope :completed, -> { where(status: "completed") }
  scope :with_adverse_results, -> { where(result: %w[consider adverse]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :expiring_soon, -> { where("expires_at <= ?", 30.days.from_now) }

  # State checks
  def pending?
    status == "pending"
  end

  def consent_required?
    status == "consent_required"
  end

  def consent_given?
    status == "consent_given"
  end

  def in_progress?
    status == "in_progress"
  end

  def review_required?
    status == "review_required"
  end

  def completed?
    status == "completed"
  end

  def cancelled?
    status == "cancelled"
  end

  def expired?
    status == "expired" || (expires_at.present? && expires_at < Time.current)
  end

  # Result checks
  def clear?
    result == "clear"
  end

  def adverse?
    result == "adverse"
  end

  def needs_review?
    result.in?(%w[consider adverse])
  end

  # Workflow actions
  def request_consent!(method: "email")
    return false unless pending?

    update!(
      status: "consent_required",
      consent_requested_at: Time.current,
      consent_method: method
    )
  end

  def record_consent!
    return false unless consent_required?

    update!(
      status: "consent_given",
      consent_given_at: Time.current
    )
  end

  def submit!
    return false unless consent_given?

    update!(
      status: "in_progress",
      submitted_at: Time.current,
      started_at: Time.current
    )
  end

  def complete!(result:, result_details: nil, result_summary: nil)
    return false unless in_progress? || review_required?

    attrs = {
      status: "completed",
      result: result,
      result_details: result_details,
      result_summary: result_summary,
      completed_at: Time.current
    }

    # If adverse, may need review
    if result.in?(%w[consider adverse])
      attrs[:status] = "review_required"
    end

    update!(attrs)
  end

  def finalize_review!(final_result: nil)
    return false unless review_required?

    update!(
      status: "completed",
      result: final_result || result,
      completed_at: Time.current
    )
  end

  def cancel!(reason: nil)
    return false if completed?

    update!(
      status: "cancelled",
      result_summary: reason
    )
  end

  def update_from_provider!(data)
    attrs = {}

    attrs[:external_id] = data[:external_id] if data[:external_id]
    attrs[:external_url] = data[:external_url] if data[:external_url]
    attrs[:result] = data[:result] if data[:result]
    attrs[:result_details] = data[:result_details] if data[:result_details]
    attrs[:result_summary] = data[:result_summary] if data[:result_summary]
    attrs[:estimated_days] = data[:estimated_days] if data[:estimated_days]

    if data[:status] == "completed"
      attrs[:status] = data[:result].in?(%w[consider adverse]) ? "review_required" : "completed"
      attrs[:completed_at] = Time.current
    elsif data[:status]
      attrs[:status] = data[:status]
    end

    update!(attrs) if attrs.any?
  end

  private

  def validate_check_types
    return if check_types.blank?

    invalid = check_types - CHECK_TYPES
    return if invalid.empty?

    errors.add(:check_types, "contains invalid types: #{invalid.join(', ')}")
  end
end
