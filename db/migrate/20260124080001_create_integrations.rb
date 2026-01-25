# frozen_string_literal: true

# Phase 6: External integrations configuration
class CreateIntegrations < ActiveRecord::Migration[8.0]
  def change
    create_table :integrations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      # Integration type and provider
      t.string :integration_type, null: false # job_board, hris, background_check, calendar
      t.string :provider, null: false # indeed, linkedin, ziprecruiter, workday, adp, bamboohr, ledgoria, checkr, sterling

      # Display
      t.string :name, null: false
      t.text :description

      # Configuration (encrypted credentials stored separately)
      t.json :settings # Non-sensitive settings
      t.string :api_key_encrypted # Encrypted API key
      t.string :api_secret_encrypted # Encrypted API secret
      t.string :webhook_secret_encrypted # For incoming webhooks

      # OAuth tokens (for OAuth-based integrations)
      t.string :access_token_encrypted
      t.string :refresh_token_encrypted
      t.datetime :token_expires_at

      # Status
      t.string :status, null: false, default: "pending" # pending, active, error, disabled
      t.text :last_error
      t.datetime :last_sync_at
      t.datetime :last_error_at

      # Sync settings
      t.boolean :auto_sync, null: false, default: true
      t.string :sync_frequency, default: "hourly" # realtime, hourly, daily

      # Soft delete
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :integrations, :discarded_at

    add_index :integrations, [:organization_id, :integration_type]
    add_index :integrations, [:organization_id, :provider]
    add_index :integrations, [:organization_id, :status]
  end
end
