# frozen_string_literal: true

# SA-06: Interview - Calendar integrations (Google, Outlook)
class CreateCalendarIntegrations < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_integrations do |t|
      t.references :user, null: false, foreign_key: true

      # Provider
      t.string :provider, null: false # google, outlook, apple
      t.string :calendar_id

      # OAuth tokens (encrypted)
      t.text :access_token_encrypted
      t.text :refresh_token_encrypted
      t.datetime :token_expires_at

      # Status
      t.boolean :active, null: false, default: true
      t.datetime :last_synced_at
      t.string :sync_error

      t.timestamps
    end

    add_index :calendar_integrations, [:user_id, :provider], unique: true
    add_index :calendar_integrations, [:user_id, :active]
  end
end
