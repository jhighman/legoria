# frozen_string_literal: true

# SA-04: Candidate - Staffing agency management
class CreateAgencies < ActiveRecord::Migration[8.0]
  def change
    create_table :agencies do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :contact_email
      t.string :contact_name
      t.decimal :fee_percentage, precision: 5, scale: 2
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :agencies, [:organization_id, :name]
    add_index :agencies, [:organization_id, :active]
  end
end
