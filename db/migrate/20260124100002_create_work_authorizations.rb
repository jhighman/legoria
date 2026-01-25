# frozen_string_literal: true

class CreateWorkAuthorizations < ActiveRecord::Migration[8.0]
  def change
    create_table :work_authorizations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true
      t.references :i9_verification, foreign_key: true

      t.string :authorization_type, null: false
      t.date :valid_from
      t.date :valid_until
      t.boolean :indefinite, default: false
      t.string :document_number
      t.string :issuing_authority
      t.boolean :reverification_required, default: false
      t.date :reverification_due_date
      t.boolean :reverification_reminder_sent, default: false
      t.datetime :reverification_reminder_sent_at

      t.references :created_by, foreign_key: { to_table: :users }
      t.references :verified_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :work_authorizations, [:organization_id, :valid_until]
    add_index :work_authorizations, [:candidate_id, :valid_until]
  end
end
