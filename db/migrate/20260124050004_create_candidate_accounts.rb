# frozen_string_literal: true

# Phase 3: Optional candidate accounts for portal access
class CreateCandidateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :candidate_accounts do |t|
      t.references :candidate, null: false, foreign_key: true, index: { unique: true }

      # Devise fields
      t.string :email, null: false
      t.string :encrypted_password, null: false, default: ""

      # Recoverable
      t.string :reset_password_token
      t.datetime :reset_password_sent_at

      # Rememberable
      t.datetime :remember_created_at

      # Trackable
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip

      # Confirmable
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email

      # Lockable
      t.integer :failed_attempts, default: 0, null: false
      t.string :unlock_token
      t.datetime :locked_at

      # Preferences
      t.boolean :email_notifications, null: false, default: true
      t.boolean :job_alerts, null: false, default: false
      t.json :job_alert_criteria

      t.timestamps
    end

    add_index :candidate_accounts, :email, unique: true
    add_index :candidate_accounts, :reset_password_token, unique: true
    add_index :candidate_accounts, :confirmation_token, unique: true
    add_index :candidate_accounts, :unlock_token, unique: true
  end
end
