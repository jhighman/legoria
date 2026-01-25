# frozen_string_literal: true

class ScorecardResponse < ApplicationRecord
  # Associations
  belongs_to :scorecard
  belongs_to :scorecard_template_item

  # Delegations
  delegate :item_type, :name, :guidance, :rating_scale, :options, to: :scorecard_template_item
  delegate :interview_participant, :user, to: :scorecard

  # Validations
  validates :scorecard_template_item_id, uniqueness: { scope: :scorecard_id }

  validate :valid_rating_value
  validate :valid_select_value
  validate :value_present_if_required

  # Scopes
  scope :with_rating, -> { where.not(rating: nil) }
  scope :with_value, -> { where("rating IS NOT NULL OR yes_no_value IS NOT NULL OR text_value IS NOT NULL OR select_value IS NOT NULL") }

  # Value accessors
  def value
    case item_type
    when "rating" then rating
    when "yes_no" then yes_no_value
    when "text" then text_value
    when "select" then select_value
    end
  end

  def value=(val)
    case item_type
    when "rating" then self.rating = val.to_i if val.present?
    when "yes_no" then self.yes_no_value = val
    when "text" then self.text_value = val
    when "select" then self.select_value = val
    end
  end

  def answered?
    value.present?
  end

  # Rating display helpers
  def rating_label
    return nil unless rating? && rating.present?

    labels = ScorecardTemplateItem::RATING_SCALES[rating_scale]
    labels&.[](rating - 1) || rating.to_s
  end

  def rating_percentage
    return nil unless rating? && rating.present?

    ((rating.to_f / rating_scale) * 100).round
  end

  # Yes/No display helpers
  def yes_no_label
    return nil unless yes_no?

    yes_no_value ? "Yes" : "No"
  end

  # Type helpers
  def rating?
    item_type == "rating"
  end

  def yes_no?
    item_type == "yes_no"
  end

  def text?
    item_type == "text"
  end

  def select?
    item_type == "select"
  end

  # Display helpers
  def display_value
    case item_type
    when "rating" then rating_label
    when "yes_no" then yes_no_label
    when "text" then text_value
    when "select" then select_value
    end
  end

  private

  def valid_rating_value
    return unless rating? && rating.present?

    max = rating_scale || 5
    unless rating.between?(1, max)
      errors.add(:rating, "must be between 1 and #{max}")
    end
  end

  def valid_select_value
    return unless select? && select_value.present?

    valid_options = scorecard_template_item.select_options
    unless valid_options.include?(select_value)
      errors.add(:select_value, "is not a valid option")
    end
  end

  def value_present_if_required
    return unless scorecard_template_item.required?
    return if answered?

    # Only validate if scorecard is being submitted
    return unless scorecard.submitting? if scorecard.respond_to?(:submitting?)

    errors.add(:base, "#{name} is required")
  end
end
