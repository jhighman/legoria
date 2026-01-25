# frozen_string_literal: true

class CreateLookupValues < ActiveRecord::Migration[8.0]
  def change
    create_table :lookup_values do |t|
      t.references :lookup_type, null: false, foreign_key: true
      t.string :code, null: false
      t.json :translations, null: false, default: {}
      t.json :metadata, default: {}
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end

    add_index :lookup_values, [:lookup_type_id, :code], unique: true
    add_index :lookup_values, [:lookup_type_id, :active, :position]
  end
end
