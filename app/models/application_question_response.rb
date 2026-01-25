# frozen_string_literal: true

class ApplicationQuestionResponse < ApplicationRecord
  # Associations
  belongs_to :application
  belongs_to :application_question

  # File attachment for file-type questions
  has_one_attached :file

  # Validations
  validates :application_question_id, uniqueness: { scope: :application_id, message: "has already been answered" }

  validate :validate_response_value
  validate :file_attached_if_required

  # Delegations
  delegate :question, :question_type, :required?, :options_list, to: :application_question

  # Value accessors - returns the appropriate value based on question type
  def value
    case question_type
    when "text", "textarea", "select"
      text_value
    when "yes_no"
      boolean_value
    when "number"
      number_value
    when "date"
      date_value
    when "multiselect"
      array_value || []
    when "file"
      file.attached? ? file : nil
    end
  end

  def value=(val)
    case question_type
    when "text", "textarea", "select"
      self.text_value = val
    when "yes_no"
      self.boolean_value = parse_boolean(val)
    when "number"
      self.number_value = val.present? ? val.to_i : nil
    when "date"
      self.date_value = val.present? ? Date.parse(val.to_s) : nil
    when "multiselect"
      self.array_value = Array(val).reject(&:blank?)
    when "file"
      self.file.attach(val) if val.present?
    end
  rescue ArgumentError, TypeError
    # Invalid value format, will be caught by validation
  end

  # Display helpers
  def display_value
    case question_type
    when "yes_no"
      boolean_value.nil? ? "" : (boolean_value ? "Yes" : "No")
    when "multiselect"
      (array_value || []).join(", ")
    when "date"
      date_value&.strftime("%B %d, %Y")
    when "file"
      file.attached? ? file.filename.to_s : ""
    else
      text_value || number_value&.to_s || ""
    end
  end

  def answered?
    case question_type
    when "yes_no"
      !boolean_value.nil?
    when "multiselect"
      array_value.present?
    when "file"
      file.attached?
    else
      value.present?
    end
  end

  private

  def parse_boolean(val)
    return nil if val.nil?
    return val if val.is_a?(TrueClass) || val.is_a?(FalseClass)

    %w[true 1 yes].include?(val.to_s.downcase)
  end

  def validate_response_value
    return unless application_question

    validation_errors = application_question.validate_response(value)
    validation_errors.each do |error|
      errors.add(:base, "#{application_question.question} #{error}")
    end
  end

  def file_attached_if_required
    return unless application_question&.file?
    return unless application_question.required?

    unless file.attached?
      errors.add(:file, "is required")
    end
  end
end
