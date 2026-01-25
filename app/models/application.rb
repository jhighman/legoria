# frozen_string_literal: true

class Application < ApplicationRecord
  include OrganizationScoped
  include Discardable
  include Auditable

  # Audit configuration
  audit_actions create: "application.created", update: "application.updated", destroy: "application.archived"

  # Status constants for the detailed workflow
  STATUSES = %w[new screening interviewing assessment background_check offered hired rejected withdrawn].freeze
  ACTIVE_STATUSES = %w[new screening interviewing assessment background_check offered].freeze
  TERMINAL_STATUSES = %w[hired rejected withdrawn].freeze

  # Source types
  SOURCE_TYPES = %w[career_site job_board referral agency direct linkedin other].freeze

  # Rating range
  RATING_RANGE = (1..5).freeze

  # Associations
  belongs_to :job
  belongs_to :candidate
  belongs_to :current_stage, class_name: "Stage"
  belongs_to :rejection_reason, optional: true

  has_many :stage_transitions, dependent: :destroy
  has_many :interviews, dependent: :destroy
  # HiringDecisions are immutable - prevent cascade delete
  has_many :hiring_decisions, dependent: :restrict_with_error
  has_many :application_question_responses, dependent: :destroy
  has_many :candidate_documents, dependent: :nullify
  has_many :offers, dependent: :destroy
  has_one :eeoc_response, dependent: :destroy
  has_many :adverse_actions, dependent: :destroy

  # Phase 8: I-9 and Work Authorization
  has_one :i9_verification, dependent: :destroy

  # Phase 5: Intelligence
  has_one :candidate_score, dependent: :destroy
  has_many :automation_logs, dependent: :nullify

  # Validations
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :source_type, presence: true
  validates :applied_at, presence: true
  validates :rating, inclusion: { in: RATING_RANGE }, allow_nil: true

  validate :candidate_not_already_applied
  validate :job_accepting_applications, on: :create
  validate :source_type_in_lookup

  # Callbacks
  before_validation :set_defaults, on: :create
  after_save :update_last_activity

  # State machine for application workflow
  # Note: initial state is :new, database default is 'active' - the state machine takes precedence
  state_machine :status, initial: :new do
    # Forward progression states
    state :new
    state :screening
    state :interviewing
    state :assessment
    state :background_check
    state :offered
    state :hired
    state :rejected
    state :withdrawn

    # Forward progression events
    event :advance_to_screening do
      transition new: :screening
    end

    event :advance_to_interviewing do
      transition [:new, :screening] => :interviewing
    end

    event :advance_to_assessment do
      transition [:screening, :interviewing] => :assessment
    end

    event :advance_to_background_check do
      transition [:interviewing, :assessment] => :background_check
    end

    event :advance_to_offer do
      transition [:interviewing, :assessment, :background_check] => :offered
    end

    # Alias for offer workflow
    event :offer do
      transition [:interviewing, :assessment, :background_check] => :offered
    end

    event :hire do
      transition offered: :hired
    end

    # Terminal events (can happen from any active state)
    event :reject do
      transition ACTIVE_STATUSES.map(&:to_sym) => :rejected
    end

    event :withdraw do
      transition ACTIVE_STATUSES.map(&:to_sym) => :withdrawn
    end

    # Move back (for corrections)
    event :move_back do
      transition screening: :new
      transition interviewing: :screening
      transition assessment: :interviewing
      transition background_check: :assessment
      transition offered: :background_check
    end

    # Callbacks
    after_transition to: :hired do |application|
      application.update_column(:hired_at, Time.current)
      application.job.increment!(:filled_count)
    end

    after_transition to: :rejected do |application|
      application.update_column(:rejected_at, Time.current)
    end

    after_transition to: :withdrawn do |application|
      application.update_column(:withdrawn_at, Time.current)
    end
  end

  # Scopes
  scope :active, -> { where(status: ACTIVE_STATUSES) }
  scope :terminal, -> { where(status: TERMINAL_STATUSES) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_job, ->(job_id) { where(job_id: job_id) if job_id.present? }
  scope :by_stage, ->(stage_id) { where(current_stage_id: stage_id) if stage_id.present? }
  scope :starred, -> { where(starred: true) }
  scope :rated, -> { where.not(rating: nil) }
  scope :unrated, -> { where(rating: nil) }
  scope :recent, -> { order(applied_at: :desc) }
  scope :by_source, ->(source) { where(source_type: source) if source.present? }

  scope :stuck, ->(days = 14) {
    active.where("last_activity_at < ?", days.days.ago)
  }

  # Status helpers
  def active?
    ACTIVE_STATUSES.include?(status)
  end

  def terminal?
    TERMINAL_STATUSES.include?(status)
  end

  def hired?
    status == "hired"
  end

  def rejected?
    status == "rejected"
  end

  def withdrawn?
    status == "withdrawn"
  end

  def can_receive_decision?
    # Application must be active and in a stage where decisions can be made
    active? && status.in?(%w[interviewing assessment background_check offered])
  end

  # Rating helpers
  def rated?
    rating.present?
  end

  def rate!(value)
    update!(rating: value)
  end

  def unrate!
    update!(rating: nil)
  end

  # Star/favorite helpers
  def star!
    update!(starred: true)
  end

  def unstar!
    update!(starred: false)
  end

  def toggle_star!
    update!(starred: !starred)
  end

  # Rejection
  def reject_with_reason!(reason:, notes: nil)
    return false unless can_reject?

    self.rejection_reason = reason
    self.rejection_notes = notes
    reject!
  end

  # Stage progression
  def current_stage_name
    current_stage&.name
  end

  def days_in_current_stage
    last_transition = stage_transitions.order(created_at: :desc).first
    return 0 unless last_transition

    ((Time.current - last_transition.created_at) / 1.day).to_i
  end

  def days_since_applied
    ((Time.current - applied_at) / 1.day).to_i
  end

  def time_to_hire
    return nil unless hired?

    ((hired_at - applied_at) / 1.day).to_i
  end

  # Display helpers
  def status_label
    status.titleize
  end

  def status_color
    case status
    when "new" then "blue"
    when "screening" then "indigo"
    when "interviewing" then "purple"
    when "assessment" then "pink"
    when "background_check" then "orange"
    when "offered" then "yellow"
    when "hired" then "green"
    when "rejected" then "red"
    when "withdrawn" then "gray"
    else "gray"
    end
  end

  def source_label
    LookupService.translate("application_source", source_type, organization: organization)
  end

  private

  def source_type_in_lookup
    return if source_type.blank?

    valid_types = if organization
                    LookupService.valid_codes("application_source", organization: organization)
                  else
                    SOURCE_TYPES
                  end

    return if valid_types.include?(source_type)

    errors.add(:source_type, "is not a valid application source")
  end

  def set_defaults
    self.applied_at ||= Time.current
    self.last_activity_at ||= Time.current
    # Don't set status here - let state_machine handle initial state
  end

  def update_last_activity
    # Don't trigger callbacks, just update the timestamp
    update_column(:last_activity_at, Time.current) if saved_change_to_status?
  end

  def candidate_not_already_applied
    return unless candidate_id.present? && job_id.present?

    existing = Application.kept
                          .where(candidate_id: candidate_id, job_id: job_id)
                          .where.not(id: id)

    errors.add(:candidate, "has already applied to this job") if existing.exists?
  end

  def job_accepting_applications
    return unless job.present?

    unless job.open?
      errors.add(:job, "is not accepting applications")
    end
  end
end
