# frozen_string_literal: true

class CreateI9Documents < ActiveRecord::Migration[8.0]
  def change
    create_table :i9_documents do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :i9_verification, null: false, foreign_key: true

      t.string :list_type, null: false
      t.string :document_type, null: false
      t.string :document_title
      t.string :issuing_authority
      t.string :document_number
      t.date :expiration_date
      t.boolean :verified, default: false
      t.references :verified_by, foreign_key: { to_table: :users }
      t.datetime :verified_at
      t.text :verification_notes

      t.timestamps
    end

    add_index :i9_documents, [:i9_verification_id, :list_type]
  end
end
