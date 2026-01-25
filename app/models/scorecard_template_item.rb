# frozen_string_literal: true

class ScorecardTemplateItem < ApplicationRecord
  # Item types
  ITEM_TYPES = %w[rating yes_no text select].freeze

  # Default rating scales
  RATING_SCALES = {
    5 => ["Strong No", "No", "Neutral", "Yes", "Strong Yes"],
    4 => ["No", "Maybe No", "Maybe Yes", "Yes"],
    3 => ["Below Expectations", "Meets Expectations", "Exceeds Expectations"]
  }.freeze

  # Associations
  belongs_to :scorecard_template_section

  has_many :scorecard_responses, dependent: :destroy

  # Delegations
  delegate :scorecard_template, to: :scorecard_template_section
  delegate :organization, to: :scorecard_template

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :item_type, presence: true, inclusion: { in: ITEM_TYPES }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rating_scale, numericality: { greater_than: 0, less_than_or_equal_to: 10 }, allow_nil: true

  validate :options_for_select_type

  # Scopes
  scope :required, -> { where(required: true) }
  scope :optional, -> { where(required: false) }
  scope :by_type, ->(type) { where(item_type: type) if type.present? }

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

  # Rating helpers
  def rating_labels
    return [] unless rating?

    RATING_SCALES[rating_scale] || (1..rating_scale).map(&:to_s)
  end

  def rating_range
    return nil unless rating?

    1..rating_scale
  end

  # Select helpers
  def select_options
    return [] unless select?

    options.is_a?(Array) ? options : []
  end

  # Position management
  def move_up
    return if position.zero?

    sibling = scorecard_template_section.scorecard_template_items.find_by(position: position - 1)
    swap_positions(sibling) if sibling
  end

  def move_down
    sibling = scorecard_template_section.scorecard_template_items.find_by(position: position + 1)
    swap_positions(sibling) if sibling
  end

  # Display helpers
  def item_type_label
    item_type.titleize.gsub("_", "/")
  end

  def full_path
    "#{scorecard_template_section.name} > #{name}"
  end

  private

  def options_for_select_type
    return unless select?

    if options.blank? || !options.is_a?(Array) || options.empty?
      errors.add(:options, "must have at least one option for select type items")
    end
  end

  def swap_positions(other)
    old_position = position
    update_column(:position, other.position)
    other.update_column(:position, old_position)
  end
end
