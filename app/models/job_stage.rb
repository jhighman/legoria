# frozen_string_literal: true

class JobStage < ApplicationRecord
  # Associations
  belongs_to :job
  belongs_to :stage

  # Delegate organization_id to job for consistency
  delegate :organization_id, to: :job

  # Validations
  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 0 },
                       uniqueness: { scope: :job_id }
  validates :stage_id, uniqueness: { scope: :job_id, message: "is already assigned to this job" }

  # Scopes
  scope :ordered, -> { order(position: :asc) }
  scope :requiring_interview, -> { where(required_interview: true) }

  # Navigation
  def next_stage
    job.job_stages.where("position > ?", position).ordered.first&.stage
  end

  def previous_stage
    job.job_stages.where("position < ?", position).ordered.last&.stage
  end

  def first?
    position == 0
  end

  def last?
    job.job_stages.where("position > ?", position).none?
  end

  def terminal?
    stage.terminal?
  end
end
