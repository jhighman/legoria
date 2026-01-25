# frozen_string_literal: true

class CreateLookupTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :lookup_types do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.string :description
      t.boolean :system_managed, default: false, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :lookup_types, [:organization_id, :code], unique: true
    add_index :lookup_types, [:organization_id, :active]
  end
end
