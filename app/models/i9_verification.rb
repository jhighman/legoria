# frozen_string_literal: true

class I9Verification < ApplicationRecord
  include OrganizationScoped
  include Auditable

  # Audit configuration
  audit_actions create: "i9.initiated", update: "i9.updated"

  # Status constants
  STATUSES = %w[pending_section1 section1_complete pending_section2 section2_complete pending_everify everify_tnc verified failed expired].freeze
  ACTIVE_STATUSES = %w[pending_section1 section1_complete pending_section2 section2_complete pending_everify everify_tnc].freeze
  TERMINAL_STATUSES = %w[verified failed expired].freeze

  # Citizenship status options (USCIS Form I-9)
  CITIZENSHIP_STATUSES = %w[citizen noncitizen_national permanent_resident alien_authorized].freeze

  # Associations
  belongs_to :application
  belongs_to :candidate
  belongs_to :section2_completed_by, class_name: "User", optional: true
  belongs_to :section3_completed_by, class_name: "User", optional: true
  belongs_to :authorized_representative, class_name: "User", optional: true

  has_many :i9_documents, dependent: :destroy
  has_one :e_verify_case, dependent: :destroy
  has_one :work_authorization, dependent: :nullify

  # Encrypt sensitive fields
  encrypts :alien_number
  encrypts :i94_number
  encrypts :foreign_passport_number

  # Validations
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :application_id, uniqueness: { scope: :organization_id, message: "already has an I-9 verification" }
  validates :citizenship_status, inclusion: { in: CITIZENSHIP_STATUSES }, allow_nil: true

  # Section field validations are handled by the service objects
  # to avoid issues with state machine transitions

  # Callbacks
  before_validation :set_deadlines, on: :create

  # State machine for I-9 workflow
  state_machine :status, initial: :pending_section1 do
    state :pending_section1
    state :section1_complete
    state :pending_section2
    state :section2_complete
    state :pending_everify
    state :everify_tnc
    state :verified
    state :failed
    state :expired

    # Section 1 completion (employee)
    event :complete_section1 do
      transition pending_section1: :section1_complete
    end

    # Begin Section 2 (employer starts review)
    event :begin_section2 do
      transition section1_complete: :pending_section2
    end

    # Section 2 completion (employer)
    event :complete_section2 do
      transition pending_section2: :section2_complete
    end

    # E-Verify submission (if required)
    event :submit_everify do
      transition section2_complete: :pending_everify
    end

    # E-Verify TNC (Tentative Non-Confirmation)
    event :receive_tnc do
      transition pending_everify: :everify_tnc
    end

    # Verification complete (final success)
    event :verify do
      transition [:section2_complete, :pending_everify, :everify_tnc] => :verified
    end

    # Verification failed
    event :fail_verification do
      transition any => :failed
    end

    # Work authorization expired
    event :expire do
      transition verified: :expired
    end

    # Callbacks
    after_transition on: :complete_section1 do |verification|
      verification.update_column(:section1_completed_at, Time.current)
      verification.application.update_column(:i9_status, "section1_complete")
    end

    after_transition on: :complete_section2 do |verification|
      verification.update_column(:section2_completed_at, Time.current)
      verification.application.update_column(:i9_status, "section2_complete")
      verification.check_late_completion!
    end

    after_transition on: :verify do |verification|
      verification.application.update_column(:i9_status, "verified")
    end

    after_transition on: :fail_verification do |verification|
      verification.application.update_column(:i9_status, "failed")
    end

    after_transition do |verification, transition|
      verification.audit_status_change(transition.from, transition.to, transition.event)
    end
  end

  # Scopes
  scope :pending, -> { where(status: ACTIVE_STATUSES) }
  scope :verified_all, -> { where(status: "verified") }
  scope :failed_all, -> { where(status: "failed") }
  scope :overdue, -> { pending.where("deadline_section2 < ?", Date.current) }
  scope :due_soon, ->(days = 3) { pending.where(deadline_section2: Date.current..days.days.from_now.to_date) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :late, -> { where(late_completion: true) }

  # Status helpers
  def active?
    ACTIVE_STATUSES.include?(status)
  end

  def terminal?
    TERMINAL_STATUSES.include?(status)
  end

  def section1_complete?
    !status.in?(%w[pending_section1])
  end

  def section2_complete?
    status.in?(%w[section2_complete pending_everify everify_tnc verified])
  end

  def awaiting_section1?
    status == "pending_section1"
  end

  def awaiting_section2?
    status.in?(%w[section1_complete pending_section2])
  end

  def awaiting_everify?
    status == "pending_everify"
  end

  # Deadline calculations (business days)
  def section2_deadline
    deadline_section2
  end

  def section2_overdue?
    return false unless deadline_section2 && !section2_completed_at
    Date.current > deadline_section2
  end

  def days_until_section2_deadline
    return nil unless deadline_section2
    return 0 if section2_completed_at

    (deadline_section2 - Date.current).to_i
  end

  def days_overdue
    return 0 unless section2_overdue?

    (Date.current - deadline_section2).to_i
  end

  # Check and mark late completion
  def check_late_completion!
    return unless section2_completed_at && deadline_section2

    if section2_completed_at.to_date > deadline_section2
      update_columns(
        late_completion: true,
        late_completion_reason: "Section 2 completed #{(section2_completed_at.to_date - deadline_section2).to_i} days after deadline"
      )
    end
  end

  # Document validation helpers
  def has_valid_list_a_document?
    i9_documents.where(list_type: "list_a", verified: true).exists?
  end

  def has_valid_list_b_and_c_documents?
    i9_documents.where(list_type: "list_b", verified: true).exists? &&
      i9_documents.where(list_type: "list_c", verified: true).exists?
  end

  def documents_valid?
    has_valid_list_a_document? || has_valid_list_b_and_c_documents?
  end

  # Display helpers
  def status_label
    case status
    when "pending_section1" then "Awaiting Employee (Section 1)"
    when "section1_complete" then "Section 1 Complete"
    when "pending_section2" then "Awaiting Employer (Section 2)"
    when "section2_complete" then "Section 2 Complete"
    when "pending_everify" then "E-Verify Pending"
    when "everify_tnc" then "E-Verify TNC"
    when "verified" then "Verified"
    when "failed" then "Failed"
    when "expired" then "Expired"
    else status.titleize.gsub("_", " ")
    end
  end

  def status_color
    case status
    when "pending_section1" then "yellow"
    when "section1_complete" then "blue"
    when "pending_section2" then "orange"
    when "section2_complete" then "indigo"
    when "pending_everify" then "purple"
    when "everify_tnc" then "red"
    when "verified" then "green"
    when "failed" then "red"
    when "expired" then "gray"
    else "gray"
    end
  end

  def citizenship_status_label
    case citizenship_status
    when "citizen" then "U.S. Citizen"
    when "noncitizen_national" then "U.S. Noncitizen National"
    when "permanent_resident" then "Lawful Permanent Resident"
    when "alien_authorized" then "Authorized Alien"
    else citizenship_status&.titleize
    end
  end

  # Audit helper
  def audit_status_change(from, to, event)
    return unless Current.organization.present?

    AuditLog.log(
      action: "i9.#{event}",
      auditable: self,
      metadata: {
        i9_verification_id: id,
        candidate_name: candidate&.full_name,
        from_status: from,
        to_status: to,
        late_completion: late_completion
      },
      recorded_changes: { status: [from, to] }
    )
  end

  private

  def set_deadlines
    return unless employee_start_date

    self.deadline_section1 = employee_start_date
    self.deadline_section2 = calculate_business_days_after(employee_start_date, 3)
  end

  def calculate_business_days_after(start_date, days)
    current = start_date
    days.times do
      current += 1.day
      current += 1.day while current.saturday? || current.sunday?
    end
    current
  end

  def section1_fields_when_complete
    unless attestation_accepted
      errors.add(:attestation_accepted, "must be accepted")
    end

    unless citizenship_status.present?
      errors.add(:citizenship_status, "is required")
    end
  end

  def section2_fields_when_complete
    unless documents_valid?
      errors.add(:base, "Valid identity and employment documents are required")
    end
  end
end
