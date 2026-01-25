# frozen_string_literal: true

# Phase 5: Individual skills for candidates (for matching)
class CandidateSkill < ApplicationRecord
  include OrganizationScoped

  belongs_to :candidate
  belongs_to :parsed_resume, optional: true

  # Categories
  CATEGORIES = %w[technical soft language certification tool domain].freeze

  # Proficiency levels
  PROFICIENCY_LEVELS = %w[beginner intermediate advanced expert].freeze

  # Sources
  SOURCES = %w[parsed self_reported inferred verified].freeze

  validates :name, presence: true
  validates :normalized_name, presence: true
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true
  validates :proficiency_level, inclusion: { in: PROFICIENCY_LEVELS }, allow_nil: true
  validates :source, inclusion: { in: SOURCES }
  validates :name, uniqueness: { scope: :candidate_id }

  # Callbacks
  before_validation :set_normalized_name

  # Scopes
  scope :by_category, ->(category) { where(category: category) }
  scope :verified, -> { where(verified: true) }
  scope :unverified, -> { where(verified: false) }
  scope :recent, -> { order(created_at: :desc) }

  # Verify the skill
  def verify!
    update!(verified: true)
  end

  private

  def set_normalized_name
    self.normalized_name = name&.downcase&.strip&.gsub(/\s+/, " ")
  end
end
