# frozen_string_literal: true

# Phase 6: HRIS export tracking
class CreateHrisExports < ActiveRecord::Migration[8.0]
  def change
    create_table :hris_exports do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :integration, null: false, foreign_key: true
      t.references :application, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true
      t.references :exported_by, null: false, foreign_key: { to_table: :users }

      # External reference
      t.string :external_id # Employee ID in HRIS
      t.string :external_url # Link to employee in HRIS

      # Export status
      t.string :status, null: false, default: "pending"
      # pending, exporting, completed, failed, cancelled

      # Data exported
      t.json :export_data # Snapshot of data sent to HRIS
      t.json :field_mapping # How ATS fields mapped to HRIS fields

      # Response
      t.json :response_data
      t.text :error_message

      # Timing
      t.datetime :exported_at
      t.datetime :confirmed_at # When HRIS confirmed receipt

      t.timestamps
    end

    add_index :hris_exports, [:application_id, :integration_id], unique: true
    add_index :hris_exports, [:organization_id, :status]
    add_index :hris_exports, :external_id
  end
end
