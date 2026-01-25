# frozen_string_literal: true

# SA-07: Evaluation - Individual scorecards filled out by interviewers
class CreateScorecards < ActiveRecord::Migration[8.0]
  def change
    create_table :scorecards do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :interview, null: false, foreign_key: true
      t.references :interview_participant, null: false, foreign_key: true
      t.references :scorecard_template, foreign_key: true

      # Status
      t.string :status, null: false, default: "draft" # draft, submitted, locked

      # Overall recommendation
      t.string :overall_recommendation # strong_hire, hire, no_decision, no_hire, strong_no_hire

      # Summary fields
      t.text :summary
      t.text :strengths
      t.text :concerns

      # Calculated score
      t.decimal :overall_score, precision: 5, scale: 2

      # Timestamps
      t.datetime :submitted_at
      t.datetime :locked_at

      # Visibility
      t.boolean :visible_to_team, null: false, default: false

      t.timestamps
    end

    add_index :scorecards, [:organization_id, :status]
    add_index :scorecards, [:interview_id, :status]
    # Note: interview_participant_id already has an index from t.references
  end
end
