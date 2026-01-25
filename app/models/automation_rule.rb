# frozen_string_literal: true

# Phase 5: Automation rules for workflow automation
class AutomationRule < ApplicationRecord
  include OrganizationScoped

  belongs_to :created_by, class_name: "User"
  belongs_to :job, optional: true

  has_many :automation_logs, dependent: :destroy

  # Rule types
  RULE_TYPES = %w[
    knockout_question
    stage_progression
    sla_alert
    email_trigger
    tag_assignment
    score_threshold
  ].freeze

  # Trigger events
  TRIGGER_EVENTS = %w[
    application_created
    application_updated
    stage_changed
    interview_completed
    scorecard_submitted
    score_calculated
    time_elapsed
  ].freeze

  validates :name, presence: true
  validates :rule_type, presence: true, inclusion: { in: RULE_TYPES }
  validates :trigger_event, presence: true, inclusion: { in: TRIGGER_EVENTS }
  validates :conditions, presence: true
  validates :actions, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_type, ->(type) { where(rule_type: type) }
  scope :by_trigger, ->(event) { where(trigger_event: event) }
  scope :for_job, ->(job_id) { where(job_id: job_id) }
  scope :org_wide, -> { where(job_id: nil) }
  scope :by_priority, -> { order(priority: :desc) }

  # Evaluate conditions against an application
  def evaluate(application)
    return false unless active?
    return false if job_id.present? && job_id != application.job_id

    evaluate_conditions(application)
  end

  # Execute actions for the rule
  def execute!(application)
    return unless evaluate(application)

    actions_taken = execute_actions(application)

    log_execution!(
      application: application,
      status: "success",
      actions_taken: actions_taken
    )

    increment_trigger_count!
    actions_taken
  rescue StandardError => e
    log_execution!(
      application: application,
      status: "failed",
      error_message: e.message
    )
    raise
  end

  # Activate the rule
  def activate!
    update!(active: true)
  end

  # Deactivate the rule
  def deactivate!
    update!(active: false)
  end

  private

  def evaluate_conditions(application)
    conds = conditions || {}
    result = true

    # Question-based condition
    if conds["question_id"].present?
      response = application.application_responses.find_by(application_question_id: conds["question_id"])
      result &&= evaluate_comparison(response&.value, conds["operator"], conds["value"])
    end

    # Score-based condition
    if conds["min_score"].present?
      score = application.candidate_score&.overall_score
      result &&= score.present? && score >= conds["min_score"].to_f
    end

    # Stage-based condition
    if conds["stage"].present?
      result &&= application.stage&.slug == conds["stage"]
    end

    # Time-based condition
    if conds["days_in_stage"].present?
      days = (Time.current - application.stage_changed_at) / 1.day
      result &&= days >= conds["days_in_stage"].to_i
    end

    result
  end

  def evaluate_comparison(actual, operator, expected)
    case operator
    when "equals"
      actual.to_s.downcase == expected.to_s.downcase
    when "not_equals"
      actual.to_s.downcase != expected.to_s.downcase
    when "contains"
      actual.to_s.downcase.include?(expected.to_s.downcase)
    when "greater_than"
      actual.to_f > expected.to_f
    when "less_than"
      actual.to_f < expected.to_f
    else
      false
    end
  end

  def execute_actions(application)
    actions_taken = []

    Array(actions).each do |action|
      case action["type"]
      when "reject"
        application.reject!
        actions_taken << { type: "reject", reason_id: action["reason_id"] }
      when "advance"
        next_stage = application.pipeline.stages.find_by(position: application.stage.position + 1)
        if next_stage
          application.update!(stage: next_stage)
          actions_taken << { type: "advance", to_stage: next_stage.name }
        end
      when "tag"
        # Tag assignment would be implemented here
        actions_taken << { type: "tag", tag: action["tag"] }
      when "notify"
        # Notification would be sent here
        actions_taken << { type: "notify", users: action["users"] }
      when "send_email"
        # Email would be sent here
        actions_taken << { type: "send_email", template: action["template"] }
      end
    end

    actions_taken
  end

  def log_execution!(application:, status:, actions_taken: nil, error_message: nil)
    automation_logs.create!(
      organization: organization,
      application: application,
      candidate: application.candidate,
      status: status,
      trigger_event: trigger_event,
      conditions_evaluated: conditions,
      actions_taken: actions_taken,
      error_message: error_message,
      triggered_at: Time.current
    )
  end

  def increment_trigger_count!
    update!(
      times_triggered: times_triggered + 1,
      last_triggered_at: Time.current
    )
  end
end
