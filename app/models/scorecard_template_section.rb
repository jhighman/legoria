# frozen_string_literal: true

class ScorecardTemplateSection < ApplicationRecord
  # Section types
  SECTION_TYPES = %w[competencies questions overall custom].freeze

  # Associations
  belongs_to :scorecard_template

  has_many :scorecard_template_items, -> { order(position: :asc) }, dependent: :destroy

  # Delegations
  delegate :organization, to: :scorecard_template

  # Nested attributes
  accepts_nested_attributes_for :scorecard_template_items,
                                allow_destroy: true,
                                reject_if: :all_blank

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :section_type, presence: true, inclusion: { in: SECTION_TYPES }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  # Scopes
  scope :required, -> { where(required: true) }
  scope :optional, -> { where(required: false) }
  scope :by_type, ->(type) { where(section_type: type) if type.present? }

  # Position management
  def move_up
    return if position.zero?

    sibling = scorecard_template.scorecard_template_sections.find_by(position: position - 1)
    swap_positions(sibling) if sibling
  end

  def move_down
    sibling = scorecard_template.scorecard_template_sections.find_by(position: position + 1)
    swap_positions(sibling) if sibling
  end

  def move_to(new_position)
    return if new_position == position

    sections = scorecard_template.scorecard_template_sections.order(:position).to_a
    sections.delete(self)
    sections.insert([new_position, sections.size].min, self)

    sections.each_with_index do |section, idx|
      section.update_column(:position, idx) if section.position != idx
    end
  end

  # Item management
  def add_item(name:, item_type: "rating", **attributes)
    max_position = scorecard_template_items.maximum(:position) || -1
    scorecard_template_items.create!(
      name: name,
      item_type: item_type,
      position: max_position + 1,
      **attributes
    )
  end

  # Type helpers
  def competencies?
    section_type == "competencies"
  end

  def questions?
    section_type == "questions"
  end

  def overall?
    section_type == "overall"
  end

  def custom?
    section_type == "custom"
  end

  # Display helpers
  def section_type_label
    section_type.titleize
  end

  def item_count
    scorecard_template_items.count
  end

  private

  def swap_positions(other)
    old_position = position
    update_column(:position, other.position)
    other.update_column(:position, old_position)
  end
end
