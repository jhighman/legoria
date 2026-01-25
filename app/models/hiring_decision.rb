# frozen_string_literal: true

class HiringDecision < ApplicationRecord
  include OrganizationScoped
  include Auditable

  # Audit configuration
  audit_actions create: "hiring_decision.created"

  # IMPORTANT: This model is IMMUTABLE. Once created, records cannot be updated or deleted.
  # If a decision needs to be changed, a new HiringDecision record should be created.

  # Decision types
  DECISIONS = %w[hire reject hold].freeze

  # Status types
  STATUSES = %w[pending approved rejected].freeze

  # Associations
  belongs_to :application
  belongs_to :decided_by, class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true

  # Delegations
  delegate :candidate, to: :application
  delegate :job, to: :application

  # Validations
  validates :decision, presence: true, inclusion: { in: DECISIONS }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :rationale, presence: true
  validates :decided_at, presence: true

  validates :proposed_salary, numericality: { greater_than: 0 }, allow_nil: true
  validates :proposed_start_date, presence: true, if: -> { hire? }

  validate :salary_required_for_hire, if: -> { hire? && status == "approved" }
  validate :one_pending_decision_per_application, on: :create

  # IMMUTABILITY: Prevent updates and destroys
  before_update :prevent_update
  before_destroy :prevent_destroy

  # Callbacks
  before_validation :set_decided_at, on: :create

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :hires, -> { where(decision: "hire") }
  scope :rejects, -> { where(decision: "reject") }
  scope :holds, -> { where(decision: "hold") }
  scope :for_application, ->(app_id) { where(application_id: app_id) if app_id.present? }
  scope :recent, -> { order(decided_at: :desc) }

  # Decision helpers
  def hire?
    decision == "hire"
  end

  def reject?
    decision == "reject"
  end

  def hold?
    decision == "hold"
  end

  # Status helpers
  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  # Decision labels
  def decision_label
    case decision
    when "hire" then "Hire"
    when "reject" then "Reject"
    when "hold" then "Hold"
    else decision.titleize
    end
  end

  def decision_color
    case decision
    when "hire" then "green"
    when "reject" then "red"
    when "hold" then "yellow"
    else "gray"
    end
  end

  def status_label
    status.titleize
  end

  def status_color
    case status
    when "pending" then "yellow"
    when "approved" then "green"
    when "rejected" then "red"
    else "gray"
    end
  end

  # Salary formatting
  def proposed_salary_formatted
    return nil if proposed_salary.blank?

    currency_symbol = case proposed_salary_currency
                      when "USD" then "$"
                      when "EUR" then "\u20AC"
                      when "GBP" then "\u00A3"
                      else ""
    end

    "#{currency_symbol}#{proposed_salary.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  # Approval workflow
  def can_approve?
    pending?
  end

  def can_reject_approval?
    pending?
  end

  # Note: These methods create audit records but don't actually update the record
  # Instead, they use update_column to bypass the immutability check for approval workflow
  def approve!(approved_by:)
    raise StandardError, "Decision cannot be approved" unless can_approve?

    transaction do
      update_columns(
        status: "approved",
        approved_by_id: approved_by.id,
        approved_at: Time.current
      )

      # Create audit log for approval
      AuditLog.log(
        action: "hiring_decision.approved",
        auditable: self,
        metadata: {
          decision: decision,
          application_id: application_id,
          approved_by_id: approved_by.id,
          approved_by_name: approved_by.full_name
        },
        recorded_changes: { status: %w[pending approved] }
      )

      # Trigger application status change if hire
      if hire?
        application.hire! if application.respond_to?(:hire!)
      elsif reject?
        application.reject! if application.respond_to?(:reject!)
      end
    end

    true
  end

  def reject_approval!(rejected_by:, reason: nil)
    raise StandardError, "Decision cannot be rejected" unless can_reject_approval?

    transaction do
      update_columns(
        status: "rejected",
        rejected_at: Time.current
      )

      # Create audit log for rejection
      AuditLog.log(
        action: "hiring_decision.rejected",
        auditable: self,
        metadata: {
          decision: decision,
          application_id: application_id,
          rejected_by_id: rejected_by.id,
          rejected_by_name: rejected_by.full_name,
          reason: reason
        },
        recorded_changes: { status: %w[pending rejected] }
      )
    end

    true
  end

  # Display helpers
  def decider_name
    decided_by.full_name
  end

  def approver_name
    approved_by&.full_name
  end

  def decided_at_formatted
    decided_at.strftime("%B %d, %Y at %I:%M %p")
  end

  def approved_at_formatted
    approved_at&.strftime("%B %d, %Y at %I:%M %p")
  end

  private

  def prevent_update
    raise ActiveRecord::ReadOnlyRecord, "HiringDecision records are immutable and cannot be updated"
  end

  def prevent_destroy
    raise ActiveRecord::ReadOnlyRecord, "HiringDecision records are immutable and cannot be destroyed"
  end

  def set_decided_at
    self.decided_at ||= Time.current
  end

  def salary_required_for_hire
    return unless proposed_salary.blank?

    errors.add(:proposed_salary, "is required for approved hire decisions")
  end

  def one_pending_decision_per_application
    existing_pending = HiringDecision.where(application_id: application_id, status: "pending")
    return unless existing_pending.exists?

    errors.add(:application, "already has a pending hiring decision")
  end
end
