# frozen_string_literal: true

class RejectionReason < ApplicationRecord
  include OrganizationScoped

  # Categories
  CATEGORIES = %w[not_qualified timing compensation culture_fit withdrew other].freeze

  # Associations
  has_many :applications, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :ordered, -> { order(position: :asc, name: :asc) }
  scope :by_category, ->(category) { where(category: category) }
  scope :requiring_notes, -> { where(requires_notes: true) }

  # Category checks
  def not_qualified?
    category == "not_qualified"
  end

  def timing?
    category == "timing"
  end

  def compensation?
    category == "compensation"
  end

  def culture_fit?
    category == "culture_fit"
  end

  def withdrew?
    category == "withdrew"
  end

  def other?
    category == "other"
  end

  # Activation
  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end
end
