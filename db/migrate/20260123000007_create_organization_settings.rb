# frozen_string_literal: true

# SA-02: Organization Management - Key-value settings store
class CreateOrganizationSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :organization_settings do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :key, null: false
      t.json :value, null: false

      t.timestamps
    end

    add_index :organization_settings, [:organization_id, :key], unique: true
  end
end
