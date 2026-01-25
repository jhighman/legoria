# frozen_string_literal: true

class CreateI9Verifications < ActiveRecord::Migration[8.0]
  def change
    create_table :i9_verifications do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :application, null: false, foreign_key: true, index: false
      t.references :candidate, null: false, foreign_key: true

      # Section 1 - Employee Information
      t.string :status, null: false, default: "pending_section1"
      t.datetime :section1_completed_at
      t.string :section1_signature_ip
      t.string :section1_signature_user_agent
      t.boolean :attestation_accepted, default: false
      t.string :citizenship_status
      t.string :alien_number
      t.date :alien_expiration_date
      t.string :i94_number
      t.string :foreign_passport_number
      t.string :foreign_passport_country

      # Section 2 - Employer Verification
      t.datetime :section2_completed_at
      t.references :section2_completed_by, foreign_key: { to_table: :users }
      t.string :section2_signature_ip
      t.date :employee_start_date
      t.string :employer_title
      t.string :employer_organization_name
      t.string :employer_organization_address

      # Section 3 - Reverification
      t.datetime :section3_completed_at
      t.references :section3_completed_by, foreign_key: { to_table: :users }
      t.date :rehire_date

      # Authorized Representative
      t.references :authorized_representative, foreign_key: { to_table: :users }
      t.boolean :remote_verification, default: false

      # Compliance
      t.date :deadline_section1
      t.date :deadline_section2
      t.boolean :late_completion, default: false
      t.text :late_completion_reason

      t.timestamps
    end

    add_index :i9_verifications, [:organization_id, :status]
    add_index :i9_verifications, [:organization_id, :deadline_section2]
    add_index :i9_verifications, [:application_id], unique: true
  end
end
