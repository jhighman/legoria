# frozen_string_literal: true

# Phase 4: Data retention policies per organization
class CreateDataRetentionPolicies < ActiveRecord::Migration[8.0]
  def change
    create_table :data_retention_policies do |t|
      t.references :organization, null: false, foreign_key: true

      # Policy name and description
      t.string :name, null: false
      t.text :description

      # What data this policy applies to
      t.string :data_category, null: false # candidate_data, application_data, interview_data, offer_data, eeoc_data

      # Retention period
      t.integer :retention_days, null: false # Days to retain after trigger
      t.string :retention_trigger, null: false # application_closed, candidate_withdrawn, offer_declined, hired

      # Actions
      t.string :action_type, null: false, default: "anonymize" # anonymize, delete, archive
      t.boolean :notify_candidate, null: false, default: true

      # Status
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :data_retention_policies, [:organization_id, :data_category]
    add_index :data_retention_policies, [:organization_id, :active]
  end
end
