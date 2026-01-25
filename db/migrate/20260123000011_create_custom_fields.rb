# frozen_string_literal: true

# SA-02: Organization Management - Custom field definitions
class CreateCustomFields < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_fields do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :entity_type, null: false # candidate, job, application
      t.string :field_key, null: false
      t.string :label, null: false
      t.string :field_type, null: false # text, number, date, select, multiselect, boolean
      t.json :options
      t.boolean :required, default: false, null: false
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :custom_fields, [:organization_id, :entity_type, :field_key], unique: true, name: "idx_custom_fields_unique_key"
    add_index :custom_fields, [:organization_id, :entity_type, :active]
  end
end
