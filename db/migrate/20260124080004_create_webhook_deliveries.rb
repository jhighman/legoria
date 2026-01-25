# frozen_string_literal: true

# Phase 6: Webhook delivery attempts and results
class CreateWebhookDeliveries < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_deliveries do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :webhook, null: false, foreign_key: true

      # Event details
      t.string :event_type, null: false
      t.string :event_id, null: false # Unique ID for this event
      t.json :payload, null: false

      # Delivery status
      t.string :status, null: false, default: "pending" # pending, success, failed, retrying
      t.integer :attempt_count, null: false, default: 0
      t.integer :max_attempts, null: false, default: 5

      # Response details
      t.integer :response_status
      t.text :response_body
      t.integer :response_time_ms

      # Error tracking
      t.text :error_message
      t.string :error_type # timeout, connection_refused, http_error, etc.

      # Timing
      t.datetime :scheduled_at
      t.datetime :delivered_at
      t.datetime :next_retry_at

      t.timestamps
    end

    add_index :webhook_deliveries, [:webhook_id, :status]
    add_index :webhook_deliveries, [:organization_id, :event_type]
    add_index :webhook_deliveries, :event_id, unique: true
    add_index :webhook_deliveries, [:status, :next_retry_at]
  end
end
