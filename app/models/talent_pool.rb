# frozen_string_literal: true

# Phase 5: Talent pools for organizing candidates
class TalentPool < ApplicationRecord
  include OrganizationScoped

  belongs_to :owner, class_name: "User"
  belongs_to :saved_search, optional: true

  has_many :talent_pool_members, dependent: :destroy
  has_many :candidates, through: :talent_pool_members

  # Pool types
  POOL_TYPES = %w[manual smart].freeze

  validates :name, presence: true
  validates :pool_type, presence: true, inclusion: { in: POOL_TYPES }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :manual, -> { where(pool_type: "manual") }
  scope :smart, -> { where(pool_type: "smart") }
  scope :shared, -> { where(shared: true) }
  scope :personal, -> { where(shared: false) }

  # Add a candidate to the pool
  def add_candidate(candidate, added_by: nil, notes: nil, source: "manual")
    return if candidates.include?(candidate)

    talent_pool_members.create!(
      candidate: candidate,
      added_by: added_by,
      notes: notes,
      source: source
    )
    increment!(:candidates_count)
  end

  # Remove a candidate from the pool
  def remove_candidate(candidate)
    member = talent_pool_members.find_by(candidate: candidate)
    return unless member

    member.destroy
    decrement!(:candidates_count)
  end

  # Refresh smart pool from saved search
  def refresh!
    return unless smart? && saved_search

    new_candidates = saved_search.execute

    # Add new candidates
    new_candidates.find_each do |candidate|
      add_candidate(candidate, source: "smart_search") unless candidates.include?(candidate)
    end
  end

  # Pool type checks
  def manual?
    pool_type == "manual"
  end

  def smart?
    pool_type == "smart"
  end

  # Deactivate the pool
  def deactivate!
    update!(active: false)
  end

  # Activate the pool
  def activate!
    update!(active: true)
  end
end
