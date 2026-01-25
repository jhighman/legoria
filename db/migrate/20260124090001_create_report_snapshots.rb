# frozen_string_literal: true

class CreateReportSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :report_snapshots do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :report_type, null: false   # eeoc, diversity, pipeline, time_to_hire
      t.string :period_type, null: false   # daily, weekly, monthly, quarterly
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.json :data, null: false, default: {}
      t.json :metadata, default: {}
      t.datetime :generated_at, null: false
      t.references :generated_by, foreign_key: { to_table: :users }  # null = system
      t.timestamps
    end

    add_index :report_snapshots, [:organization_id, :report_type, :period_start],
              name: "idx_report_snapshots_org_type_period"
    add_index :report_snapshots, [:organization_id, :report_type, :period_type],
              name: "idx_report_snapshots_org_type_period_type"
  end
end
