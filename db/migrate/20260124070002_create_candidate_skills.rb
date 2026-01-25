# frozen_string_literal: true

# Phase 5: Extracted skills from resumes (normalized)
class CreateCandidateSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :candidate_skills do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true
      t.references :parsed_resume, foreign_key: true

      # Skill info
      t.string :name, null: false
      t.string :normalized_name # Lowercase, trimmed for matching
      t.string :category # technical, soft, language, tool, framework, etc.
      t.string :proficiency_level # beginner, intermediate, advanced, expert
      t.integer :years_experience

      # Source
      t.string :source, null: false, default: "parsed" # parsed, manual, inferred

      # Verification
      t.boolean :verified, null: false, default: false
      t.references :verified_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :candidate_skills, [:organization_id, :normalized_name]
    add_index :candidate_skills, [:candidate_id, :name], unique: true
    add_index :candidate_skills, :category
  end
end
