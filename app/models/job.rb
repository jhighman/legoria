# frozen_string_literal: true

class Job < ApplicationRecord
  include OrganizationScoped
  include Discardable
  include Auditable

  # Audit configuration
  audit_actions create: "job.created", update: "job.updated", destroy: "job.archived"
  audit_exclude :internal_notes

  # Fallback constants (used when organization lookup types not available)
  EMPLOYMENT_TYPES = %w[full_time part_time contract intern temporary].freeze
  LOCATION_TYPES = %w[onsite remote hybrid].freeze
  CLOSE_REASONS = %w[filled cancelled on_hold].freeze

  # Associations
  belongs_to :department, optional: true
  belongs_to :hiring_manager, class_name: "User", optional: true
  belongs_to :recruiter, class_name: "User", optional: true

  has_many :job_stages, dependent: :destroy
  has_many :stages, through: :job_stages
  has_many :job_approvals, dependent: :destroy
  has_many :applications, dependent: :restrict_with_error
  has_many :application_questions, -> { order(position: :asc) }, dependent: :destroy

  # Phase 5: Intelligence
  has_many :job_requirements, -> { order(position: :asc) }, dependent: :destroy
  has_many :automation_rules, dependent: :destroy
  has_many :candidate_scores, dependent: :destroy

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :employment_type, presence: true
  validates :location_type, presence: true
  validates :headcount, numericality: { only_integer: true, greater_than: 0 }
  validates :filled_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :salary_min, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :salary_max, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :close_reason, inclusion: { in: CLOSE_REASONS }, allow_nil: true

  validate :salary_range_valid
  validate :filled_count_within_headcount
  validate :employment_type_in_lookup
  validate :location_type_in_lookup

  # Callbacks
  after_create :create_default_stages

  # State machine
  state_machine :status, initial: :draft do
    # States
    state :draft
    state :pending_approval
    state :open
    state :on_hold
    state :closed

    # Events
    event :submit_for_approval do
      transition draft: :pending_approval
    end

    event :approve do
      transition pending_approval: :open
    end

    event :reject do
      transition pending_approval: :draft
    end

    event :reopen do
      transition [:on_hold, :closed] => :open
    end

    event :put_on_hold do
      transition open: :on_hold
    end

    event :close do
      transition [:open, :on_hold] => :closed
    end

    # Callbacks
    after_transition to: :open do |job|
      job.update_column(:opened_at, Time.current) if job.opened_at.nil?
    end

    after_transition to: :closed do |job|
      job.update_column(:closed_at, Time.current)
    end

    # Audit logging for status changes
    after_transition do |job, transition|
      job.audit_status_change(transition.from, transition.to, transition.event)
    end
  end

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :by_department, ->(department_id) { where(department_id: department_id) }
  scope :by_hiring_manager, ->(user_id) { where(hiring_manager_id: user_id) }
  scope :by_recruiter, ->(user_id) { where(recruiter_id: user_id) }
  scope :open_jobs, -> { where(status: :open) }
  scope :active, -> { where(status: [:draft, :pending_approval, :open, :on_hold]) }

  # Status helpers
  def pending_approval?
    status == "pending_approval"
  end

  def open?
    status == "open"
  end

  def closed?
    status == "closed"
  end

  def on_hold?
    status == "on_hold"
  end

  def draft?
    status == "draft"
  end

  def editable?
    draft? || pending_approval?
  end

  def filled?
    filled_count >= headcount
  end

  def remaining_openings
    [headcount - filled_count, 0].max
  end

  # Approval helpers
  def current_approval
    job_approvals.pending.order(created_at: :desc).first
  end

  def approved_by?(user)
    job_approvals.approved.where(approver: user).exists?
  end

  def rejected_by?(user)
    job_approvals.rejected.where(approver: user).exists?
  end

  def requires_approval?
    draft? && hiring_manager.present?
  end

  # Salary helpers
  def salary_range
    return nil unless salary_min || salary_max

    if salary_min && salary_max
      "#{format_salary(salary_min)} - #{format_salary(salary_max)}"
    elsif salary_min
      "From #{format_salary(salary_min)}"
    else
      "Up to #{format_salary(salary_max)}"
    end
  end

  def format_salary(cents)
    return nil unless cents

    Money.new(cents, salary_currency).format
  rescue
    "$#{(cents / 100.0).round}"
  end

  # Duplication
  def duplicate
    dup.tap do |new_job|
      new_job.status = "draft"
      new_job.opened_at = nil
      new_job.closed_at = nil
      new_job.close_reason = nil
      new_job.filled_count = 0
      new_job.remote_id = nil
    end
  end

  # Display helpers using lookup translations
  def employment_type_display
    LookupService.translate("employment_type", employment_type, organization: organization)
  end

  def location_type_display
    LookupService.translate("location_type", location_type, organization: organization)
  end

  # Audit logging for status changes
  def audit_status_change(from_status, to_status, event)
    return unless Current.organization.present?

    AuditLog.log(
      action: "job.status_changed",
      auditable: self,
      metadata: {
        event: event,
        from_status: from_status,
        to_status: to_status,
        title: title
      },
      recorded_changes: { status: [from_status, to_status] }
    )
  end

  private

  def salary_range_valid
    return unless salary_min && salary_max
    return if salary_max >= salary_min

    errors.add(:salary_max, "must be greater than or equal to minimum salary")
  end

  def filled_count_within_headcount
    return unless filled_count && headcount
    return if filled_count <= headcount

    errors.add(:filled_count, "cannot exceed headcount")
  end

  def employment_type_in_lookup
    return if employment_type.blank?

    valid_types = lookup_codes_for("employment_type")
    return if valid_types.include?(employment_type)

    errors.add(:employment_type, "is not a valid employment type")
  end

  def location_type_in_lookup
    return if location_type.blank?

    valid_types = lookup_codes_for("location_type")
    return if valid_types.include?(location_type)

    errors.add(:location_type, "is not a valid location type")
  end

  def lookup_codes_for(type_code)
    if organization
      LookupService.valid_codes(type_code, organization: organization)
    else
      # Fallback to constants when organization not available
      case type_code
      when "employment_type" then EMPLOYMENT_TYPES
      when "location_type" then LOCATION_TYPES
      else []
      end
    end
  end

  def create_default_stages
    return if job_stages.any?

    organization.stages.default_stages.each_with_index do |stage, index|
      job_stages.create!(stage: stage, position: index)
    end
  end
end
