# frozen_string_literal: true

# Phase 5: Candidate match scores for jobs
class CandidateScore < ApplicationRecord
  include OrganizationScoped

  belongs_to :application
  belongs_to :job
  belongs_to :candidate
  belongs_to :overridden_by, class_name: "User", optional: true

  validates :overall_score, presence: true,
                            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :scored_at, presence: true
  validates :application_id, uniqueness: true

  # Scopes
  scope :high_scoring, -> { where("overall_score >= ?", 80) }
  scope :medium_scoring, -> { where("overall_score >= ? AND overall_score < ?", 50, 80) }
  scope :low_scoring, -> { where("overall_score < ?", 50) }
  scope :recent, -> { order(scored_at: :desc) }
  scope :by_score, -> { order(overall_score: :desc) }
  scope :not_overridden, -> { where(manual_override: false) }
  scope :overridden, -> { where(manual_override: true) }

  # Score category
  def score_category
    if overall_score >= 80
      "high"
    elsif overall_score >= 50
      "medium"
    else
      "low"
    end
  end

  # Get component score
  def component_score(component)
    component_scores&.dig(component.to_s)
  end

  # Get explanation for component
  def explanation_for(component)
    score_explanation&.dig(component.to_s)
  end

  # Skills match data
  def skills_match
    explanation_for("skills_match") || {}
  end

  def matched_skills
    skills_match["matched"] || []
  end

  def missing_skills
    skills_match["missing"] || []
  end

  def bonus_skills
    skills_match["bonus"] || []
  end

  # Override the score manually
  def override!(new_score:, overrider:, reason: nil)
    explanation = score_explanation || {}
    explanation["manual_override"] = {
      original_score: overall_score,
      new_score: new_score,
      reason: reason,
      overridden_at: Time.current.iso8601
    }

    update!(
      overall_score: new_score,
      manual_override: true,
      overridden_by: overrider,
      score_explanation: explanation
    )
  end

  # Recalculate the score
  def recalculate!
    # Would call ScoringService here
    update!(
      scored_at: Time.current,
      manual_override: false,
      overridden_by: nil
    )
  end
end
