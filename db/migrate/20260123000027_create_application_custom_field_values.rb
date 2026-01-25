# frozen_string_literal: true

# SA-05: Application Pipeline - Custom field values for applications
class CreateApplicationCustomFieldValues < ActiveRecord::Migration[8.0]
  def change
    create_table :application_custom_field_values do |t|
      t.references :application, null: false, foreign_key: true
      t.references :custom_field, null: false, foreign_key: true
      t.text :value

      t.timestamps
    end

    add_index :application_custom_field_values, [:application_id, :custom_field_id], unique: true, name: "idx_application_cfv_unique"
  end
end
