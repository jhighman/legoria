# frozen_string_literal: true

# Phase 5: Membership of candidates in talent pools
class TalentPoolMember < ApplicationRecord
  belongs_to :talent_pool
  belongs_to :candidate
  belongs_to :added_by, class_name: "User", optional: true

  # Sources
  SOURCES = %w[manual smart_search import].freeze

  validates :source, inclusion: { in: SOURCES }
  validates :candidate_id, uniqueness: { scope: :talent_pool_id }

  # Delegate organization for scoping
  delegate :organization_id, to: :talent_pool

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_source, ->(source) { where(source: source) }
  scope :manually_added, -> { where(source: "manual") }
  scope :from_search, -> { where(source: "smart_search") }
  scope :imported, -> { where(source: "import") }
end
