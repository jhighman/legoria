# frozen_string_literal: true

# SA-01: Identity & Access - User aggregate root
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.references :organization, null: false, foreign_key: true

      # Authentication
      t.string :email, null: false
      t.string :encrypted_password

      # Profile
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :avatar_url

      # Status
      t.boolean :active, default: true, null: false
      t.datetime :confirmed_at
      t.datetime :locked_at
      t.integer :failed_attempts, default: 0, null: false
      t.string :unlock_token

      # Tracking
      t.datetime :last_sign_in_at
      t.string :last_sign_in_ip
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :password_changed_at

      t.timestamps
    end

    # Email unique per organization
    add_index :users, [:organization_id, :email], unique: true
    add_index :users, :email
    add_index :users, :unlock_token, unique: true, where: "unlock_token IS NOT NULL"
    add_index :users, :active
  end
end
