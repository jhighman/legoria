# frozen_string_literal: true

# SA-01: Identity & Access - Session and API key management
class CreateUserSessionsAndApiKeys < ActiveRecord::Migration[8.0]
  def change
    # User sessions for session-based auth
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.string :ip_address
      t.string :user_agent
      t.datetime :expires_at, null: false
      t.datetime :last_active_at

      t.datetime :created_at, null: false
    end

    add_index :user_sessions, :token_digest, unique: true
    add_index :user_sessions, :expires_at

    # API keys for programmatic access
    create_table :api_keys do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :key_prefix, null: false
      t.string :key_digest, null: false
      t.json :scopes, default: [], null: false
      t.datetime :last_used_at
      t.datetime :expires_at
      t.datetime :revoked_at

      t.datetime :created_at, null: false
    end

    add_index :api_keys, :key_digest, unique: true
    add_index :api_keys, :key_prefix
    add_index :api_keys, [:organization_id, :revoked_at]
  end
end
