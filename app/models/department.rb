# frozen_string_literal: true

class Department < ApplicationRecord
  include OrganizationScoped

  # Associations
  belongs_to :parent, class_name: "Department", optional: true
  has_many :children, class_name: "Department", foreign_key: :parent_id, dependent: :destroy
  belongs_to :default_hiring_manager, class_name: "User", optional: true

  has_many :jobs, dependent: :nullify

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, length: { maximum: 50 },
                   uniqueness: { scope: :organization_id, allow_nil: true }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :parent_belongs_to_same_organization
  validate :no_circular_reference

  # Scopes
  scope :ordered, -> { order(position: :asc, name: :asc) }
  scope :roots, -> { where(parent_id: nil) }
  scope :with_children, -> { includes(:children) }

  # Hierarchy helpers
  def root?
    parent_id.nil?
  end

  def leaf?
    children.empty?
  end

  def ancestors
    result = []
    current = parent
    while current
      result << current
      current = current.parent
    end
    result
  end

  def descendants
    result = []
    children.each do |child|
      result << child
      result.concat(child.descendants)
    end
    result
  end

  def depth
    ancestors.count
  end

  def full_path
    (ancestors.reverse + [self]).map(&:name).join(" > ")
  end

  private

  def parent_belongs_to_same_organization
    return unless parent.present?
    return if parent.organization_id == organization_id

    errors.add(:parent, "must belong to the same organization")
  end

  def no_circular_reference
    return unless parent.present?
    return unless persisted?

    if parent_id == id || parent.ancestors.any? { |a| a.id == id }
      errors.add(:parent, "would create a circular reference")
    end
  end
end
