# frozen_string_literal: true

# Phase 5: Candidate match scores for jobs
class CreateCandidateScores < ActiveRecord::Migration[8.0]
  def change
    create_table :candidate_scores do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :application, null: false, foreign_key: true, index: { unique: true }
      t.references :job, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true

      # Overall score (0-100)
      t.decimal :overall_score, precision: 5, scale: 2, null: false

      # Component scores (JSON)
      t.json :component_scores
      # Example:
      # {
      #   "skills_match": 85,
      #   "experience_match": 70,
      #   "education_match": 90,
      #   "location_match": 100,
      #   "culture_fit": null
      # }

      # Score breakdown explanation (for transparency)
      t.json :score_explanation
      # Example:
      # {
      #   "skills_match": {
      #     "matched": ["Ruby", "Rails", "PostgreSQL"],
      #     "missing": ["Kubernetes"],
      #     "bonus": ["AWS"]
      #   },
      #   "experience_match": {
      #     "required": 5,
      #     "candidate_has": 4,
      #     "note": "1 year short of requirement"
      #   }
      # }

      # Scoring metadata
      t.string :scoring_version # Algorithm version
      t.datetime :scored_at, null: false
      t.boolean :manual_override, null: false, default: false
      t.references :overridden_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :candidate_scores, [:job_id, :overall_score]
    add_index :candidate_scores, [:organization_id, :overall_score]
  end
end
