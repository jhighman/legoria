# frozen_string_literal: true

class Interview < ApplicationRecord
  include OrganizationScoped
  include Discardable
  include Auditable

  # Audit configuration
  audit_actions create: "interview.scheduled", update: "interview.updated", destroy: "interview.archived"
  audit_exclude :instructions

  # Interview types
  INTERVIEW_TYPES = %w[phone_screen video onsite panel technical cultural_fit].freeze

  # Status constants
  STATUSES = %w[scheduled confirmed completed cancelled no_show].freeze
  ACTIVE_STATUSES = %w[scheduled confirmed].freeze
  TERMINAL_STATUSES = %w[completed cancelled no_show].freeze

  # Default durations by type (in minutes)
  DEFAULT_DURATIONS = {
    "phone_screen" => 30,
    "video" => 45,
    "onsite" => 60,
    "panel" => 90,
    "technical" => 90,
    "cultural_fit" => 45
  }.freeze

  # Associations
  belongs_to :application
  belongs_to :job
  belongs_to :scheduled_by, class_name: "User"

  has_many :interview_participants, dependent: :destroy
  has_many :participants, through: :interview_participants, source: :user
  has_many :scorecards, dependent: :nullify
  has_one :self_schedule, class_name: "InterviewSelfSchedule", dependent: :destroy

  # Validations
  validates :interview_type, presence: true, inclusion: { in: INTERVIEW_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :title, presence: true, length: { maximum: 255 }
  validates :scheduled_at, presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 480 }
  validates :timezone, presence: true

  validate :scheduled_in_future, on: :create
  validate :application_active, on: :create
  validate :not_scheduling_conflict, on: :create

  # Callbacks
  before_validation :set_defaults, on: :create

  # State machine for interview workflow
  state_machine :status, initial: :scheduled do
    state :scheduled
    state :confirmed
    state :completed
    state :cancelled
    state :no_show

    # Progression events
    event :confirm do
      transition scheduled: :confirmed
    end

    event :complete do
      transition [:scheduled, :confirmed] => :completed
    end

    event :cancel do
      transition [:scheduled, :confirmed] => :cancelled
    end

    event :mark_no_show do
      transition [:scheduled, :confirmed] => :no_show
    end

    # Callbacks
    after_transition to: :confirmed do |interview|
      interview.update_column(:confirmed_at, Time.current)
    end

    after_transition to: :completed do |interview|
      interview.update_column(:completed_at, Time.current)
    end

    after_transition to: :cancelled do |interview|
      interview.update_column(:cancelled_at, Time.current)
    end

    after_transition do |interview, transition|
      interview.audit_status_change(transition.from, transition.to, transition.event)
    end
  end

  # Scopes
  scope :upcoming, -> { active.where("scheduled_at > ?", Time.current).order(scheduled_at: :asc) }
  scope :past, -> { where("scheduled_at < ?", Time.current).order(scheduled_at: :desc) }
  scope :today, -> { where(scheduled_at: Time.current.all_day) }
  scope :this_week, -> { where(scheduled_at: Time.current.all_week) }
  scope :active, -> { where(status: ACTIVE_STATUSES) }
  scope :terminal, -> { where(status: TERMINAL_STATUSES) }
  scope :by_type, ->(type) { where(interview_type: type) if type.present? }
  scope :for_user, ->(user_id) { joins(:interview_participants).where(interview_participants: { user_id: user_id }) }
  scope :needing_feedback, -> { completed.joins(:interview_participants).where(interview_participants: { feedback_submitted: false }) }

  # Status helpers
  def active?
    ACTIVE_STATUSES.include?(status)
  end

  def terminal?
    TERMINAL_STATUSES.include?(status)
  end

  def upcoming?
    scheduled_at > Time.current && active?
  end

  def past?
    scheduled_at < Time.current
  end

  # Participant helpers
  def lead_interviewer
    interview_participants.find_by(role: "lead")&.user
  end

  def interviewers
    interview_participants.where(role: %w[lead interviewer]).includes(:user).map(&:user)
  end

  def add_participant(user, role: "interviewer")
    interview_participants.find_or_create_by(user: user) do |ip|
      ip.role = role
    end
  end

  def remove_participant(user)
    interview_participants.find_by(user: user)&.destroy
  end

  def all_feedback_submitted?
    interview_participants.where(role: %w[lead interviewer]).all?(&:feedback_submitted)
  end

  def feedback_pending_count
    interview_participants.where(role: %w[lead interviewer], feedback_submitted: false).count
  end

  # Time helpers
  def end_time
    scheduled_at + duration_minutes.minutes
  end

  def duration_formatted
    hours = duration_minutes / 60
    mins = duration_minutes % 60

    if hours > 0 && mins > 0
      "#{hours}h #{mins}m"
    elsif hours > 0
      "#{hours} hour#{'s' if hours > 1}"
    else
      "#{mins} minutes"
    end
  end

  def scheduled_at_formatted(format: :long)
    scheduled_at.in_time_zone(timezone).strftime(
      case format
      when :short then "%b %d, %I:%M %p"
      when :date then "%B %d, %Y"
      when :time then "%I:%M %p %Z"
      else "%B %d, %Y at %I:%M %p %Z"
      end
    )
  end

  def time_until
    return nil unless upcoming?

    distance = scheduled_at - Time.current
    if distance < 1.hour
      "#{(distance / 1.minute).to_i} minutes"
    elsif distance < 1.day
      "#{(distance / 1.hour).to_i} hours"
    else
      "#{(distance / 1.day).to_i} days"
    end
  end

  # Display helpers
  def interview_type_label
    interview_type.titleize.gsub("_", " ")
  end

  def status_label
    status.titleize.gsub("_", " ")
  end

  def status_color
    case status
    when "scheduled" then "blue"
    when "confirmed" then "green"
    when "completed" then "gray"
    when "cancelled" then "red"
    when "no_show" then "orange"
    else "gray"
    end
  end

  # Audit helper
  def audit_status_change(from, to, event)
    return unless Current.organization.present?

    AuditLog.log(
      action: "interview.#{event}",
      auditable: self,
      metadata: {
        interview_id: id,
        interview_title: title,
        from_status: from,
        to_status: to,
        candidate_name: application&.candidate&.full_name,
        job_title: job&.title
      },
      recorded_changes: { status: [from, to] }
    )
  end

  # Reminder helpers
  def candidate_reminder_due?
    upcoming? && scheduled_at.between?(Time.current, 24.hours.from_now)
  end

  def interviewer_reminder_due?
    upcoming? && scheduled_at.between?(Time.current, 1.hour.from_now)
  end

  private

  def set_defaults
    self.duration_minutes ||= DEFAULT_DURATIONS[interview_type] || 60
    self.timezone ||= Current.organization&.timezone || "UTC"
    self.title ||= "#{interview_type_label} Interview - #{application&.candidate&.full_name}"
  end

  def scheduled_in_future
    return if scheduled_at.blank?

    errors.add(:scheduled_at, "must be in the future") if scheduled_at <= Time.current
  end

  def application_active
    return if application.blank?

    errors.add(:application, "is not active") unless application.active?
  end

  def not_scheduling_conflict
    return if scheduled_at.blank? || duration_minutes.blank?

    # SQLite-compatible conflict detection
    conflicting = Interview.kept
                           .where(application_id: application_id)
                           .where.not(id: id)
                           .where(status: ACTIVE_STATUSES)
                           .where("scheduled_at < ? AND datetime(scheduled_at, '+' || duration_minutes || ' minutes') > ?",
                                  end_time.utc.iso8601, scheduled_at.utc.iso8601)

    errors.add(:scheduled_at, "conflicts with another interview") if conflicting.exists?
  end
end
