# frozen_string_literal: true

class QuestionBank < ApplicationRecord
  include OrganizationScoped

  # Question types
  QUESTION_TYPES = %w[behavioral technical situational cultural].freeze

  # Difficulty levels
  DIFFICULTY_LEVELS = %w[easy medium hard].freeze

  # Associations
  belongs_to :competency, optional: true

  has_many :interview_kit_questions, dependent: :nullify

  # Validations
  validates :question, presence: true
  validates :question_type, presence: true, inclusion: { in: QUESTION_TYPES }
  validates :difficulty, inclusion: { in: DIFFICULTY_LEVELS }, allow_blank: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_type, ->(type) { where(question_type: type) if type.present? }
  scope :by_difficulty, ->(diff) { where(difficulty: diff) if diff.present? }
  scope :by_competency, ->(competency_id) { where(competency_id: competency_id) if competency_id.present? }
  scope :most_used, -> { order(usage_count: :desc) }
  scope :search, ->(query) { where("question LIKE ?", "%#{query}%") if query.present? }

  # Type helpers
  def behavioral?
    question_type == "behavioral"
  end

  def technical?
    question_type == "technical"
  end

  def situational?
    question_type == "situational"
  end

  def cultural?
    question_type == "cultural"
  end

  # Difficulty helpers
  def easy?
    difficulty == "easy"
  end

  def medium?
    difficulty == "medium"
  end

  def hard?
    difficulty == "hard"
  end

  # Usage tracking
  def record_usage!
    increment!(:usage_count)
  end

  # Tags management (stored as comma-separated string)
  def tags_array
    return [] if tags.blank?

    tags.split(",").map(&:strip)
  end

  def tags_array=(array)
    self.tags = Array(array).reject(&:blank?).join(",")
  end

  def add_tag(tag)
    current_tags = tags_array
    return if current_tags.include?(tag)

    self.tags_array = current_tags + [tag]
    save!
  end

  def remove_tag(tag)
    self.tags_array = tags_array - [tag]
    save!
  end

  def has_tag?(tag)
    tags_array.include?(tag)
  end

  # Display helpers
  def question_type_label
    question_type.titleize
  end

  def difficulty_label
    return "Not specified" if difficulty.blank?

    difficulty.titleize
  end

  def difficulty_color
    case difficulty
    when "easy" then "green"
    when "medium" then "yellow"
    when "hard" then "red"
    else "gray"
    end
  end

  def truncated_question(length: 100)
    return question if question.length <= length

    "#{question[0..length]}..."
  end

  # Activation helpers
  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end
end
