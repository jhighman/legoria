# frozen_string_literal: true

# Phase 5: Job requirements for candidate matching/scoring
class JobRequirement < ApplicationRecord
  include OrganizationScoped

  belongs_to :job

  # Requirement types
  REQUIREMENT_TYPES = %w[skill experience education certification language].freeze

  # Importance levels
  IMPORTANCE_LEVELS = %w[required preferred nice_to_have].freeze

  # Education levels
  EDUCATION_LEVELS = %w[high_school associate bachelor master doctorate].freeze

  validates :requirement_type, presence: true, inclusion: { in: REQUIREMENT_TYPES }
  validates :name, presence: true
  validates :normalized_name, presence: true
  validates :importance, presence: true, inclusion: { in: IMPORTANCE_LEVELS }
  validates :weight, presence: true,
                     numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }
  validates :education_level, inclusion: { in: EDUCATION_LEVELS }, allow_nil: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Callbacks
  before_validation :set_normalized_name
  before_validation :set_default_position

  # Scopes
  scope :by_type, ->(type) { where(requirement_type: type) }
  scope :required, -> { where(importance: "required") }
  scope :preferred, -> { where(importance: "preferred") }
  scope :nice_to_have, -> { where(importance: "nice_to_have") }
  scope :ordered, -> { order(:position) }

  # Skills requirements
  scope :skills, -> { by_type("skill") }
  scope :experience_requirements, -> { by_type("experience") }
  scope :education_requirements, -> { by_type("education") }
  scope :certification_requirements, -> { by_type("certification") }
  scope :language_requirements, -> { by_type("language") }

  # Type checks
  def skill?
    requirement_type == "skill"
  end

  def experience?
    requirement_type == "experience"
  end

  def education?
    requirement_type == "education"
  end

  def certification?
    requirement_type == "certification"
  end

  def language?
    requirement_type == "language"
  end

  # Importance checks
  def required?
    importance == "required"
  end

  def preferred?
    importance == "preferred"
  end

  def nice_to_have?
    importance == "nice_to_have"
  end

  # Check if candidate meets this requirement
  def met_by?(candidate)
    case requirement_type
    when "skill"
      candidate.candidate_skills.exists?(normalized_name: normalized_name)
    when "experience"
      return true unless min_years
      (candidate.years_experience || 0) >= min_years
    when "education"
      return true unless education_level
      education_rank(candidate.highest_education) >= education_rank(education_level)
    when "certification"
      candidate.candidate_skills.where(category: "certification", normalized_name: normalized_name).exists?
    when "language"
      candidate.candidate_skills.where(category: "language", normalized_name: normalized_name).exists?
    else
      false
    end
  end

  private

  def set_normalized_name
    self.normalized_name = name&.downcase&.strip&.gsub(/\s+/, " ")
  end

  def set_default_position
    return if position.present?

    max_position = job&.job_requirements&.maximum(:position) || -1
    self.position = max_position + 1
  end

  def education_rank(level)
    EDUCATION_LEVELS.index(level) || -1
  end
end
