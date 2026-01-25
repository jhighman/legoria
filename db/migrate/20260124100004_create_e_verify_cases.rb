# frozen_string_literal: true

class CreateEVerifyCases < ActiveRecord::Migration[8.0]
  def change
    create_table :e_verify_cases do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :i9_verification, null: false, foreign_key: true

      t.string :case_number
      t.string :status, null: false, default: "pending"
      t.datetime :submitted_at
      t.datetime :response_received_at
      t.string :response_code
      t.text :response_message
      t.boolean :tnc_contested, default: false
      t.date :tnc_referral_date
      t.date :tnc_response_deadline
      t.references :submitted_by, foreign_key: { to_table: :users }
      t.json :api_responses, default: []

      t.timestamps
    end

    add_index :e_verify_cases, [:organization_id, :status]
    add_index :e_verify_cases, :case_number, unique: true
  end
end
