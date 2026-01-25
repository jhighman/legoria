# frozen_string_literal: true

# Phase 5: Parsed resume data from resume parsing service
class CreateParsedResumes < ActiveRecord::Migration[8.0]
  def change
    create_table :parsed_resumes do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true
      t.references :resume, foreign_key: true

      # Parsing metadata
      t.string :parser_provider # sovren, textkernel, internal
      t.string :parser_version
      t.string :status, null: false, default: "pending" # pending, processing, completed, failed
      t.text :error_message

      # Parsed contact info
      t.string :parsed_name
      t.string :parsed_email
      t.string :parsed_phone
      t.string :parsed_location
      t.string :parsed_linkedin_url

      # Parsed summary
      t.text :summary
      t.text :objective

      # Structured data (JSON)
      t.json :work_experience # Array of jobs
      t.json :education # Array of education entries
      t.json :skills # Array of skills with categories
      t.json :certifications # Array of certifications
      t.json :languages # Array of languages with proficiency
      t.json :raw_response # Full response from parser

      # Calculated fields
      t.integer :years_of_experience
      t.string :highest_education_level # high_school, associate, bachelor, master, doctorate
      t.date :most_recent_job_end

      # Review status
      t.boolean :reviewed, null: false, default: false
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :parsed_resumes, [:organization_id, :status]
    add_index :parsed_resumes, [:candidate_id, :created_at]
  end
end
