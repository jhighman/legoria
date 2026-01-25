# frozen_string_literal: true

class AddI9FieldsToApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :applications, :i9_required, :boolean, default: true
    add_column :applications, :i9_status, :string, default: "not_started"
    add_column :applications, :expected_start_date, :date

    add_index :applications, [:organization_id, :i9_status]
  end
end
