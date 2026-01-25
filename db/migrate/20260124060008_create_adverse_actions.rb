# frozen_string_literal: true

# Phase 4: Adverse action workflow (FCRA compliance)
class CreateAdverseActions < ActiveRecord::Migration[8.0]
  def change
    create_table :adverse_actions do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :application, null: false, foreign_key: true
      t.references :initiated_by, null: false, foreign_key: { to_table: :users }

      # Adverse action type
      t.string :action_type, null: false # rejection, offer_withdrawal, termination

      # Status workflow
      t.string :status, null: false, default: "draft" # draft, pre_adverse_sent, waiting_period, final_sent, completed, cancelled

      # Reason
      t.string :reason_category, null: false # background_check, credential_verification, reference_check, other
      t.text :reason_details
      t.string :background_check_provider # If based on background check

      # Pre-adverse action notice
      t.datetime :pre_adverse_sent_at
      t.text :pre_adverse_content
      t.string :pre_adverse_delivery_method # email, mail, both

      # Waiting period (typically 5 business days for FCRA)
      t.integer :waiting_period_days, null: false, default: 5
      t.datetime :waiting_period_ends_at
      t.boolean :candidate_disputed, null: false, default: false
      t.text :dispute_details
      t.datetime :dispute_received_at

      # Final adverse action
      t.datetime :final_adverse_sent_at
      t.text :final_adverse_content
      t.string :final_adverse_delivery_method

      # Documentation
      t.json :attached_documents # Consumer report, dispute materials, etc.

      t.timestamps
    end

    add_index :adverse_actions, [:organization_id, :status]
    add_index :adverse_actions, [:application_id, :status]
    add_index :adverse_actions, :waiting_period_ends_at
  end
end
