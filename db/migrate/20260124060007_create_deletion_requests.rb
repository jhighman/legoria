# frozen_string_literal: true

# Phase 4: Right-to-deletion (GDPR Article 17) requests
class CreateDeletionRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :deletion_requests do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true
      t.references :processed_by, foreign_key: { to_table: :users }

      # Request details
      t.string :status, null: false, default: "pending" # pending, in_progress, completed, rejected
      t.string :request_source, null: false # candidate_portal, email, verbal, legal

      # Verification
      t.boolean :identity_verified, null: false, default: false
      t.string :verification_method # email_confirmation, id_check, phone

      # Processing
      t.text :rejection_reason
      t.json :data_deleted # Record of what was deleted
      t.json :data_retained # Record of what was retained (with reason)

      # Timestamps
      t.datetime :requested_at, null: false
      t.datetime :verified_at
      t.datetime :processed_at
      t.datetime :completed_at

      # Legal hold (prevents deletion)
      t.boolean :legal_hold, null: false, default: false
      t.text :legal_hold_reason

      t.timestamps
    end

    add_index :deletion_requests, [:organization_id, :status]
    add_index :deletion_requests, [:candidate_id, :status]
    add_index :deletion_requests, :requested_at
  end
end
