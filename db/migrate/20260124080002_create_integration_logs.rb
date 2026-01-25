# frozen_string_literal: true

# Phase 6: Integration sync activity logs
class CreateIntegrationLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :integration_logs do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :integration, null: false, foreign_key: true

      # What happened
      t.string :action, null: false # sync, push, pull, auth, webhook_received
      t.string :status, null: false # success, failed, partial
      t.string :direction, null: false # inbound, outbound

      # Details
      t.string :resource_type # Job, Candidate, Application, etc.
      t.bigint :resource_id
      t.string :external_id # ID in the external system

      # Request/Response (for debugging)
      t.json :request_data
      t.json :response_data
      t.text :error_message

      # Metrics
      t.integer :records_processed, default: 0
      t.integer :records_created, default: 0
      t.integer :records_updated, default: 0
      t.integer :records_failed, default: 0
      t.integer :duration_ms

      t.datetime :started_at, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :integration_logs, [:integration_id, :created_at]
    add_index :integration_logs, [:organization_id, :action]
    add_index :integration_logs, [:resource_type, :resource_id]
  end
end
