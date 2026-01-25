# frozen_string_literal: true

class EVerifyCase < ApplicationRecord
  include OrganizationScoped
  include Auditable

  # Audit configuration
  audit_actions create: "everify.case_created", update: "everify.case_updated"

  # Status constants
  STATUSES = %w[pending submitted employment_authorized tnc_issued fnc_issued closed].freeze
  ACTIVE_STATUSES = %w[pending submitted tnc_issued].freeze
  TERMINAL_STATUSES = %w[employment_authorized fnc_issued closed].freeze

  # TNC (Tentative Non-Confirmation) response deadline (federal working days)
  TNC_RESPONSE_DAYS = 8

  # Associations
  belongs_to :i9_verification
  belongs_to :submitted_by, class_name: "User", optional: true

  # Delegations
  delegate :candidate, :application, to: :i9_verification

  # Validations
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :case_number, uniqueness: true, allow_nil: true

  # State machine for E-Verify workflow
  state_machine :status, initial: :pending do
    state :pending
    state :submitted
    state :employment_authorized
    state :tnc_issued
    state :fnc_issued
    state :closed

    # Submit case to E-Verify
    event :submit do
      transition pending: :submitted
    end

    # E-Verify confirms employment authorized
    event :authorize do
      transition submitted: :employment_authorized
    end

    # E-Verify issues TNC (Tentative Non-Confirmation)
    event :issue_tnc do
      transition submitted: :tnc_issued
    end

    # E-Verify issues FNC (Final Non-Confirmation)
    event :issue_fnc do
      transition [:submitted, :tnc_issued] => :fnc_issued
    end

    # Case resolved after TNC contested
    event :resolve_tnc do
      transition tnc_issued: :employment_authorized
    end

    # Close case (manual or system)
    event :close do
      transition any => :closed
    end

    # Callbacks
    after_transition on: :submit do |everify_case|
      everify_case.update_column(:submitted_at, Time.current)
      everify_case.i9_verification.submit_everify!
    end

    after_transition on: :authorize do |everify_case|
      everify_case.update_column(:response_received_at, Time.current)
      everify_case.i9_verification.verify!
    end

    after_transition on: :issue_tnc do |everify_case|
      everify_case.update!(
        response_received_at: Time.current,
        tnc_referral_date: Date.current,
        tnc_response_deadline: everify_case.calculate_tnc_deadline
      )
      everify_case.i9_verification.receive_tnc!
    end

    after_transition on: :issue_fnc do |everify_case|
      everify_case.update_column(:response_received_at, Time.current)
      everify_case.i9_verification.fail_verification!
    end

    after_transition on: :resolve_tnc do |everify_case|
      everify_case.i9_verification.verify!
    end

    after_transition do |everify_case, transition|
      everify_case.audit_status_change(transition.from, transition.to, transition.event)
    end
  end

  # Scopes
  scope :pending_all, -> { where(status: "pending") }
  scope :submitted_all, -> { where(status: "submitted") }
  scope :awaiting_response, -> { where(status: %w[submitted tnc_issued]) }
  scope :tnc_pending, -> { where(status: "tnc_issued").where(tnc_contested: false) }
  scope :tnc_contested_all, -> { where(status: "tnc_issued").where(tnc_contested: true) }
  scope :authorized, -> { where(status: "employment_authorized") }
  scope :fnc_issued_all, -> { where(status: "fnc_issued") }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  # Status helpers
  def active?
    ACTIVE_STATUSES.include?(status)
  end

  def terminal?
    TERMINAL_STATUSES.include?(status)
  end

  def awaiting_response?
    status.in?(%w[submitted tnc_issued])
  end

  def requires_employee_action?
    status == "tnc_issued" && !tnc_contested
  end

  # TNC helpers
  def tnc_deadline_passed?
    return false unless tnc_response_deadline

    Date.current > tnc_response_deadline
  end

  def days_until_tnc_deadline
    return nil unless tnc_response_deadline

    (tnc_response_deadline - Date.current).to_i
  end

  def contest_tnc!(referral_date: nil)
    raise StandardError, "Cannot contest - not in TNC status" unless status == "tnc_issued"

    update!(
      tnc_contested: true,
      tnc_referral_date: referral_date || Date.current
    )
  end

  def calculate_tnc_deadline
    # 8 federal working days from TNC issuance
    current = Date.current
    days_added = 0

    while days_added < TNC_RESPONSE_DAYS
      current += 1.day
      days_added += 1 unless current.saturday? || current.sunday?
    end

    current
  end

  # API response logging
  def log_response(response_data)
    self.api_responses = (api_responses || []) + [
      {
        timestamp: Time.current.iso8601,
        data: response_data
      }
    ]
    save!
  end

  # Display helpers
  def status_label
    case status
    when "pending" then "Pending Submission"
    when "submitted" then "Awaiting Response"
    when "employment_authorized" then "Employment Authorized"
    when "tnc_issued" then "TNC Issued"
    when "fnc_issued" then "Final Non-Confirmation"
    when "closed" then "Closed"
    else status&.titleize
    end
  end

  def status_color
    case status
    when "pending" then "gray"
    when "submitted" then "blue"
    when "employment_authorized" then "green"
    when "tnc_issued" then "orange"
    when "fnc_issued" then "red"
    when "closed" then "gray"
    else "gray"
    end
  end

  # Audit helper
  def audit_status_change(from, to, event)
    return unless Current.organization.present?

    AuditLog.log(
      action: "everify.#{event}",
      auditable: self,
      metadata: {
        everify_case_id: id,
        case_number: case_number,
        candidate_name: candidate&.full_name,
        from_status: from,
        to_status: to,
        tnc_contested: tnc_contested
      },
      recorded_changes: { status: [from, to] }
    )
  end
end
