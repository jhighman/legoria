# frozen_string_literal: true

# Phase 5: Automation execution logs
class CreateAutomationLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :automation_logs do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :automation_rule, null: false, foreign_key: true
      t.references :application, foreign_key: true
      t.references :candidate, foreign_key: true

      # Execution details
      t.string :status, null: false # success, failed, skipped
      t.string :trigger_event, null: false

      # What happened
      t.json :conditions_evaluated # Snapshot of conditions at time of evaluation
      t.json :actions_taken # What actions were executed
      t.text :error_message # If failed

      # Timing
      t.datetime :triggered_at, null: false
      t.integer :execution_time_ms

      t.timestamps
    end

    add_index :automation_logs, [:organization_id, :created_at]
    add_index :automation_logs, [:automation_rule_id, :status]
    add_index :automation_logs, [:application_id, :created_at]
  end
end
