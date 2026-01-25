# frozen_string_literal: true

class LookupType < ApplicationRecord
  # Standard lookup type codes
  STANDARD_TYPES = %w[
    employment_type
    location_type
    application_source
    note_visibility
    stage_type
  ].freeze

  # Associations
  belongs_to :organization
  has_many :lookup_values, dependent: :destroy

  # Validations
  validates :code, presence: true,
                   uniqueness: { scope: :organization_id, case_sensitive: false },
                   format: { with: /\A[a-z][a-z0-9_]*\z/, message: "must be lowercase with underscores" }
  validates :name, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_code, ->(code) { where(code: code) }
  scope :ordered, -> { order(:name) }

  # Class methods
  def self.for_organization(org)
    where(organization: org)
  end

  # Instance methods
  def values_for_select(locale: I18n.locale)
    lookup_values.active.ordered.map do |v|
      [v.name(locale: locale), v.code]
    end
  end

  def default_value
    lookup_values.active.find_by(is_default: true)
  end
end
