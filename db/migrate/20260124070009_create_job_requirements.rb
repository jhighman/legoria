# frozen_string_literal: true

# Phase 5: Job requirements for matching/scoring
class CreateJobRequirements < ActiveRecord::Migration[8.0]
  def change
    create_table :job_requirements do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :job, null: false, foreign_key: true

      # Requirement details
      t.string :requirement_type, null: false # skill, experience, education, certification, language
      t.string :name, null: false # e.g., "Ruby", "Bachelor's Degree", "5 years experience"
      t.string :normalized_name # For matching

      # Importance
      t.string :importance, null: false, default: "required" # required, preferred, nice_to_have
      t.integer :weight, null: false, default: 1 # For scoring (1-10)

      # For experience requirements
      t.integer :min_years
      t.integer :max_years

      # For education requirements
      t.string :education_level # high_school, associate, bachelor, master, doctorate
      t.string :field_of_study

      # Display
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :job_requirements, [:job_id, :requirement_type]
    add_index :job_requirements, [:organization_id, :normalized_name]
    add_index :job_requirements, [:job_id, :position]
  end
end
