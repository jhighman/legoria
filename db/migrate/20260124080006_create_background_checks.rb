# frozen_string_literal: true

# Phase 6: Background check requests and results
class CreateBackgroundChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :background_checks do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :application, null: false, foreign_key: true, index: { unique: true }
      t.references :candidate, null: false, foreign_key: true
      t.references :integration, null: false, foreign_key: true
      t.references :requested_by, null: false, foreign_key: { to_table: :users }

      # External reference
      t.string :external_id # ID in the background check provider's system
      t.string :external_url # Link to view results in provider's portal

      # Check configuration
      t.string :package # Package/product name (e.g., "basic", "comprehensive")
      t.json :check_types # Types of checks requested
      # Example: ["criminal", "employment", "education", "credit", "drug_screen"]

      # Status workflow
      t.string :status, null: false, default: "pending"
      # pending, consent_required, in_progress, review_required, completed, cancelled, expired

      # Results
      t.string :result # clear, consider, adverse, incomplete
      t.json :result_details # Detailed results per check type
      t.text :result_summary

      # Consent tracking
      t.datetime :consent_requested_at
      t.datetime :consent_given_at
      t.string :consent_method # email, portal, in_person

      # Timing
      t.datetime :submitted_at
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :expires_at
      t.integer :estimated_days # Estimated completion time

      # Adverse action link
      t.references :adverse_action, foreign_key: true

      t.timestamps
    end

    add_index :background_checks, [:organization_id, :status]
    add_index :background_checks, :external_id
    add_index :background_checks, [:candidate_id, :created_at]
  end
end
