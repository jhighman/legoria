# frozen_string_literal: true

# Phase 4: Job offers with compensation details and approval workflow
class CreateOffers < ActiveRecord::Migration[8.0]
  def change
    create_table :offers do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :application, null: false, foreign_key: true
      t.references :offer_template, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      # Offer details
      t.string :title, null: false
      t.string :status, null: false, default: "draft" # draft, pending_approval, approved, sent, accepted, declined, withdrawn, expired

      # Compensation
      t.decimal :salary, precision: 12, scale: 2
      t.string :salary_period, default: "yearly" # yearly, monthly, hourly
      t.string :currency, default: "USD"
      t.decimal :signing_bonus, precision: 12, scale: 2
      t.decimal :annual_bonus_target, precision: 5, scale: 2 # percentage
      t.string :equity_type # options, rsu, none
      t.integer :equity_shares
      t.string :equity_vesting_schedule

      # Employment details
      t.string :employment_type # full_time, part_time, contractor, intern
      t.date :proposed_start_date
      t.string :work_location
      t.string :reports_to
      t.string :department

      # Offer content
      t.text :custom_terms
      t.text :rendered_content # Final rendered offer letter

      # Deadlines
      t.datetime :expires_at
      t.datetime :sent_at
      t.datetime :responded_at

      # Response
      t.string :response # accepted, declined
      t.text :decline_reason

      # E-signature tracking
      t.string :signature_request_id
      t.string :signature_status
      t.datetime :signed_at

      t.timestamps
    end

    add_index :offers, [:organization_id, :status]
    add_index :offers, [:application_id, :status]
    add_index :offers, :signature_request_id
  end
end
