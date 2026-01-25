# frozen_string_literal: true

# Phase 5: Saved candidate searches
class CreateSavedSearches < ActiveRecord::Migration[8.0]
  def change
    create_table :saved_searches do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      # Search info
      t.string :name, null: false
      t.text :description

      # Search criteria (JSON)
      t.json :criteria, null: false
      # Example: {
      #   "query": "software engineer",
      #   "skills": ["ruby", "rails"],
      #   "location": "San Francisco",
      #   "min_experience": 3,
      #   "education_level": "bachelor",
      #   "sources": ["career_site", "linkedin"]
      # }

      # Search type
      t.string :search_type, null: false, default: "candidate" # candidate, application

      # Alerts
      t.boolean :alert_enabled, null: false, default: false
      t.string :alert_frequency # daily, weekly
      t.datetime :last_alert_at
      t.integer :last_result_count

      # Usage tracking
      t.integer :run_count, null: false, default: 0
      t.datetime :last_run_at

      # Sharing
      t.boolean :shared, null: false, default: false

      t.timestamps
    end

    add_index :saved_searches, [:organization_id, :user_id]
    add_index :saved_searches, [:organization_id, :shared]
    add_index :saved_searches, :alert_enabled
  end
end
