# frozen_string_literal: true

# Phase 5: Saved searches for talent discovery
class SavedSearch < ApplicationRecord
  include OrganizationScoped

  belongs_to :user

  # Associations with talent pools (smart pools use saved searches)
  has_many :talent_pools, dependent: :nullify

  # Search types
  SEARCH_TYPES = %w[candidate application].freeze

  # Alert frequencies
  ALERT_FREQUENCIES = %w[daily weekly].freeze

  validates :name, presence: true
  validates :criteria, presence: true
  validates :search_type, presence: true, inclusion: { in: SEARCH_TYPES }
  validates :alert_frequency, inclusion: { in: ALERT_FREQUENCIES }, allow_nil: true

  # Scopes
  scope :shared, -> { where(shared: true) }
  scope :personal, -> { where(shared: false) }
  scope :with_alerts, -> { where(alert_enabled: true) }
  scope :recent, -> { order(last_run_at: :desc) }

  # Execute this search (returns candidate scope)
  def execute
    scope = Candidate.where(organization_id: organization_id)

    # Apply search criteria
    search_criteria = criteria || {}

    # Full-text search on search_text
    if search_criteria["query"].present?
      scope = scope.where("search_text LIKE ?", "%#{search_criteria['query']}%")
    end

    # Skills filter
    if search_criteria["skills"].present?
      skill_names = Array(search_criteria["skills"]).map(&:downcase)
      # Find candidates with matching skills
      candidate_ids = CandidateSkill.where(organization_id: organization_id)
                                     .where("normalized_name IN (?)", skill_names)
                                     .select(:candidate_id)
      scope = scope.where(id: candidate_ids)
    end

    # Experience filter
    if search_criteria["min_experience"].present?
      scope = scope.where("years_experience >= ?", search_criteria["min_experience"].to_i)
    end
    if search_criteria["max_experience"].present?
      scope = scope.where("years_experience <= ?", search_criteria["max_experience"].to_i)
    end

    # Education filter
    if search_criteria["education_level"].present?
      scope = scope.where(highest_education: search_criteria["education_level"])
    end

    # Location filter
    if search_criteria["location"].present?
      scope = scope.where("location LIKE ?", "%#{search_criteria['location']}%")
    end

    scope
  end

  # Record that the search was run
  def record_run!(results_count)
    update!(
      last_run_at: Time.current,
      last_result_count: results_count,
      run_count: run_count + 1
    )
  end

  # Check for new candidates matching the search (for alerts)
  def new_candidates_since(since_time)
    execute.where("candidates.created_at > ?", since_time)
  end
end
