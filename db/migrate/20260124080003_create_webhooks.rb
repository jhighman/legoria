# frozen_string_literal: true

# Phase 6: Outbound webhooks for event notifications
class CreateWebhooks < ActiveRecord::Migration[8.0]
  def change
    create_table :webhooks do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      # Webhook configuration
      t.string :name, null: false
      t.text :description
      t.string :url, null: false
      t.string :secret_encrypted # For HMAC signature verification

      # Events to trigger
      t.json :events, null: false
      # Example: ["application.created", "application.stage_changed", "candidate.hired"]

      # HTTP configuration
      t.string :http_method, null: false, default: "POST"
      t.json :headers # Custom headers to include

      # Status
      t.boolean :active, null: false, default: true
      t.string :status, null: false, default: "active" # active, failing, disabled

      # Stats
      t.integer :success_count, null: false, default: 0
      t.integer :failure_count, null: false, default: 0
      t.integer :consecutive_failures, null: false, default: 0
      t.datetime :last_triggered_at
      t.datetime :last_success_at
      t.datetime :last_failure_at

      # Soft delete
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :webhooks, :discarded_at

    add_index :webhooks, [:organization_id, :active]
    add_index :webhooks, :status
  end
end
