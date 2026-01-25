# frozen_string_literal: true

class InterviewKitQuestion < ApplicationRecord
  # Associations
  belongs_to :interview_kit
  belongs_to :question_bank, optional: true

  # Validations
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :time_allocation, numericality: { greater_than: 0, less_than_or_equal_to: 120 }, allow_nil: true

  validate :question_or_question_bank_present

  # Callbacks
  before_validation :set_default_position, on: :create
  after_create :increment_question_bank_usage
  after_destroy :decrement_question_bank_usage

  # Scopes
  scope :ordered, -> { order(position: :asc) }
  scope :with_question_bank, -> { where.not(question_bank_id: nil) }
  scope :custom_questions, -> { where(question_bank_id: nil) }

  # Delegations
  delegate :organization, to: :interview_kit

  # Question content accessors
  def display_question
    if question_bank.present?
      question_bank.question
    else
      question
    end
  end

  def display_guidance
    if question_bank.present? && guidance.blank?
      question_bank.guidance
    else
      guidance
    end
  end

  def question_type
    question_bank&.question_type
  end

  def difficulty
    question_bank&.difficulty
  end

  # From question bank?
  def from_library?
    question_bank.present?
  end

  def custom?
    question_bank.blank?
  end

  # Time helpers
  def time_allocation_formatted
    return nil if time_allocation.blank?

    if time_allocation >= 60
      "#{time_allocation / 60}h #{time_allocation % 60}m".gsub(" 0m", "")
    else
      "#{time_allocation} min#{'s' if time_allocation > 1}"
    end
  end

  # Move up/down in order
  def move_up!
    return if position.zero?

    transaction do
      sibling = interview_kit.interview_kit_questions.find_by(position: position - 1)
      if sibling
        sibling.update_column(:position, position)
        update_column(:position, position - 1)
      end
    end
  end

  def move_down!
    max_position = interview_kit.interview_kit_questions.maximum(:position)
    return if position >= max_position

    transaction do
      sibling = interview_kit.interview_kit_questions.find_by(position: position + 1)
      if sibling
        sibling.update_column(:position, position)
        update_column(:position, position + 1)
      end
    end
  end

  private

  def question_or_question_bank_present
    return if question_bank.present? || question.present?

    errors.add(:base, "Either a question from the library or a custom question must be provided")
  end

  def set_default_position
    return if position.present?

    max_position = interview_kit.interview_kit_questions.maximum(:position)
    self.position = max_position.to_i + 1
  end

  def increment_question_bank_usage
    question_bank&.record_usage!
  end

  def decrement_question_bank_usage
    # Optionally decrement usage count when removed from kit
    # question_bank&.decrement!(:usage_count) if question_bank&.usage_count&.positive?
  end
end
