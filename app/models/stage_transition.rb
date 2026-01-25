# frozen_string_literal: true

class StageTransition < ApplicationRecord
  # This model is IMMUTABLE - records cannot be updated or deleted
  # This ensures a complete audit trail of candidate movement through stages

  # Associations
  belongs_to :application
  belongs_to :from_stage, class_name: "Stage", optional: true
  belongs_to :to_stage, class_name: "Stage"
  belongs_to :moved_by, class_name: "User", optional: true

  # Validations
  validates :to_stage_id, presence: true

  validate :stages_different, if: -> { from_stage_id.present? }

  # Immutability enforcement
  before_update :prevent_update
  before_destroy :prevent_destroy

  # Callbacks
  before_create :calculate_duration
  after_create :create_audit_log

  # Scopes
  scope :for_application, ->(application_id) { where(application_id: application_id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }
  scope :by_stage, ->(stage_id) { where(to_stage_id: stage_id) }
  scope :by_mover, ->(user_id) { where(moved_by_id: user_id) }

  scope :today, -> { where(created_at: Time.current.all_day) }
  scope :this_week, -> { where(created_at: Time.current.all_week) }

  # Display helpers
  def from_stage_name
    from_stage&.name || "New Application"
  end

  def to_stage_name
    to_stage&.name
  end

  def mover_name
    moved_by&.full_name || "System"
  end

  def description
    if from_stage.present?
      "Moved from #{from_stage_name} to #{to_stage_name}"
    else
      "Applied to #{to_stage_name}"
    end
  end

  def duration_formatted
    return nil unless duration_hours.present?

    if duration_hours < 24
      "#{duration_hours} hours"
    elsif duration_hours < 168 # 7 days
      "#{(duration_hours / 24.0).round(1)} days"
    else
      "#{(duration_hours / 168.0).round(1)} weeks"
    end
  end

  # Analytics helpers
  def self.average_time_in_stage(stage_id)
    where(from_stage_id: stage_id)
      .where.not(duration_hours: nil)
      .average(:duration_hours)
      &.round(1)
  end

  def self.transitions_count_by_stage
    group(:to_stage_id).count
  end

  private

  def stages_different
    if from_stage_id == to_stage_id
      errors.add(:to_stage_id, "must be different from the current stage")
    end
  end

  def calculate_duration
    return unless from_stage_id.present?

    # Find the previous transition to the from_stage
    previous_transition = application.stage_transitions
                                     .where(to_stage_id: from_stage_id)
                                     .order(created_at: :desc)
                                     .first

    if previous_transition
      self.duration_hours = ((Time.current - previous_transition.created_at) / 1.hour).round
    end
  end

  def prevent_update
    raise ActiveRecord::ReadOnlyRecord, "StageTransition records are immutable and cannot be updated"
  end

  def prevent_destroy
    raise ActiveRecord::ReadOnlyRecord, "StageTransition records are immutable and cannot be deleted"
  end

  def create_audit_log
    return unless Current.organization.present?

    AuditLog.log(
      action: "application.stage_changed",
      auditable: application,
      metadata: {
        from_stage: from_stage&.name,
        to_stage: to_stage.name,
        moved_by: moved_by&.display_name,
        candidate_name: application.candidate&.full_name,
        job_title: application.job&.title
      },
      recorded_changes: {
        current_stage_id: [from_stage_id, to_stage_id]
      }
    )
  end
end
