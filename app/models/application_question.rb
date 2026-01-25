# frozen_string_literal: true

class ApplicationQuestion < ApplicationRecord
  # Question types
  QUESTION_TYPES = %w[text textarea select multiselect yes_no number date file].freeze

  # Associations
  belongs_to :job

  has_many :application_question_responses, dependent: :destroy

  # Validations
  validates :question, presence: true, length: { maximum: 500 }
  validates :question_type, presence: true, inclusion: { in: QUESTION_TYPES }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validates :min_length, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_length, numericality: { greater_than: 0 }, allow_nil: true
  validates :min_value, numericality: true, allow_nil: true
  validates :max_value, numericality: true, allow_nil: true

  validate :options_required_for_select_types
  validate :length_constraints_valid
  validate :value_constraints_valid

  # Callbacks
  before_validation :set_default_position, on: :create

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :ordered, -> { order(position: :asc) }
  scope :required_questions, -> { where(required: true) }

  # Type helpers
  def text?
    question_type == "text"
  end

  def textarea?
    question_type == "textarea"
  end

  def select?
    question_type == "select"
  end

  def multiselect?
    question_type == "multiselect"
  end

  def yes_no?
    question_type == "yes_no"
  end

  def number?
    question_type == "number"
  end

  def date?
    question_type == "date"
  end

  def file?
    question_type == "file"
  end

  def select_type?
    select? || multiselect?
  end

  def text_type?
    text? || textarea?
  end

  # Options helpers
  def options_list
    return [] unless options.is_a?(Array)

    options
  end

  def options_for_select
    options_list.map { |opt| [opt, opt] }
  end

  # Display helpers
  def question_type_label
    case question_type
    when "text" then "Short Text"
    when "textarea" then "Long Text"
    when "select" then "Single Choice"
    when "multiselect" then "Multiple Choice"
    when "yes_no" then "Yes/No"
    when "number" then "Number"
    when "date" then "Date"
    when "file" then "File Upload"
    else question_type.titleize
    end
  end

  def input_type
    case question_type
    when "text" then "text"
    when "textarea" then "textarea"
    when "select" then "select"
    when "multiselect" then "select"
    when "yes_no" then "radio"
    when "number" then "number"
    when "date" then "date"
    when "file" then "file"
    else "text"
    end
  end

  # Validation helpers
  def validate_response(value)
    errors = []

    if required? && value.blank?
      errors << "is required"
      return errors
    end

    return errors if value.blank?

    case question_type
    when "text", "textarea"
      errors << "is too short (minimum #{min_length} characters)" if min_length && value.length < min_length
      errors << "is too long (maximum #{max_length} characters)" if max_length && value.length > max_length
    when "number"
      num = value.to_f
      errors << "must be at least #{min_value}" if min_value && num < min_value
      errors << "must be at most #{max_value}" if max_value && num > max_value
    when "select"
      errors << "is not a valid option" unless options_list.include?(value)
    when "multiselect"
      selected = Array(value)
      invalid = selected - options_list
      errors << "contains invalid options: #{invalid.join(', ')}" if invalid.any?
    end

    errors
  end

  # Position management
  def move_up!
    return if position.zero?

    transaction do
      sibling = job.application_questions.find_by(position: position - 1)
      if sibling
        sibling.update_column(:position, position)
        update_column(:position, position - 1)
      end
    end
  end

  def move_down!
    max_position = job.application_questions.maximum(:position)
    return if position >= max_position

    transaction do
      sibling = job.application_questions.find_by(position: position + 1)
      if sibling
        sibling.update_column(:position, position)
        update_column(:position, position + 1)
      end
    end
  end

  # Activation
  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end

  # Duplication
  def duplicate
    dup.tap do |new_question|
      new_question.position = job.application_questions.maximum(:position).to_i + 1
    end
  end

  private

  def set_default_position
    return if position.present?

    max_position = job&.application_questions&.maximum(:position)
    self.position = max_position.to_i + 1
  end

  def options_required_for_select_types
    return unless select_type?

    if options.blank? || !options.is_a?(Array) || options.empty?
      errors.add(:options, "are required for #{question_type_label} questions")
    end
  end

  def length_constraints_valid
    return unless min_length && max_length

    if min_length > max_length
      errors.add(:min_length, "cannot be greater than max length")
    end
  end

  def value_constraints_valid
    return unless min_value && max_value

    if min_value > max_value
      errors.add(:min_value, "cannot be greater than max value")
    end
  end
end
