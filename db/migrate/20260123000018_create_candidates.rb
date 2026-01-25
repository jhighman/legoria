# frozen_string_literal: true

# SA-04: Candidate - Candidate aggregate root
# PII fields use Rails encryption
class CreateCandidates < ActiveRecord::Migration[8.0]
  def change
    create_table :candidates do |t|
      t.references :organization, null: false, foreign_key: true

      # Identity - email/phone encrypted at application layer
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone

      # Profile
      t.string :location
      t.string :linkedin_url
      t.string :portfolio_url
      t.text :summary

      # Source references
      t.references :referred_by, foreign_key: { to_table: :users }
      t.references :agency, foreign_key: true

      # Merge tracking
      t.references :merged_into, foreign_key: { to_table: :candidates }
      t.datetime :merged_at

      # Parsed/aggregated data
      t.json :parsed_profile, default: {}

      t.datetime :discarded_at
      t.timestamps
    end

    # Unique candidate per org (by email)
    add_index :candidates, [:organization_id, :email], unique: true
    add_index :candidates, :email
    add_index :candidates, [:organization_id, :last_name, :first_name]
    add_index :candidates, :discarded_at
  end
end
