# frozen_string_literal: true

class Stage < ApplicationRecord
  include OrganizationScoped

  # Stage types
  STAGE_TYPES = %w[applied screening interview offer hired rejected].freeze

  # Associations
  has_many :job_stages, dependent: :destroy
  has_many :jobs, through: :job_stages
  has_many :applications, foreign_key: :current_stage_id, dependent: :restrict_with_error
  has_many :stage_transitions_to, class_name: "StageTransition", foreign_key: :to_stage_id, dependent: :restrict_with_error
  has_many :stage_transitions_from, class_name: "StageTransition", foreign_key: :from_stage_id, dependent: :nullify

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :stage_type, presence: true, inclusion: { in: STAGE_TYPES }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, allow_nil: true }

  # Scopes
  scope :ordered, -> { order(position: :asc) }
  scope :default_stages, -> { where(is_default: true).ordered }
  scope :terminal, -> { where(is_terminal: true) }
  scope :active, -> { where(is_terminal: false) }
  scope :by_type, ->(type) { where(stage_type: type) }

  # Stage type checks
  def applied?
    stage_type == "applied"
  end

  def screening?
    stage_type == "screening"
  end

  def interview?
    stage_type == "interview"
  end

  def offer?
    stage_type == "offer"
  end

  def hired?
    stage_type == "hired"
  end

  def rejected?
    stage_type == "rejected"
  end

  def terminal?
    is_terminal?
  end

  def active?
    !is_terminal?
  end

  # Get the next stage in sequence
  def next_stage
    organization.stages.where("position > ?", position).ordered.first
  end

  # Get the previous stage in sequence
  def previous_stage
    organization.stages.where("position < ?", position).ordered.last
  end
end
