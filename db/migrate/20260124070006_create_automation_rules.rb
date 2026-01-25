# frozen_string_literal: true

# Phase 5: Automation rules for workflow automation
class CreateAutomationRules < ActiveRecord::Migration[8.0]
  def change
    create_table :automation_rules do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :job, foreign_key: true # Optional - can be org-wide or job-specific

      # Rule info
      t.string :name, null: false
      t.text :description
      t.string :rule_type, null: false
      # Rule types:
      # - knockout_question: Auto-reject based on question answer
      # - stage_progression: Auto-advance after conditions met
      # - sla_alert: Alert when candidate stuck in stage
      # - email_trigger: Send email on event
      # - tag_assignment: Auto-tag based on criteria

      # Trigger (when to evaluate)
      t.string :trigger_event, null: false
      # Events: application_created, application_updated, stage_changed,
      #         interview_completed, scorecard_submitted, time_elapsed

      # Conditions (JSON)
      t.json :conditions
      # Example for knockout:
      # { "question_id": 123, "operator": "equals", "value": "no" }
      # Example for SLA:
      # { "stage": "screening", "days_in_stage": 7 }

      # Actions (JSON array)
      t.json :actions
      # Example:
      # [
      #   { "type": "reject", "reason_id": 456 },
      #   { "type": "send_email", "template": "rejection" },
      #   { "type": "notify", "users": ["recruiter"] }
      # ]

      # Status
      t.boolean :active, null: false, default: true
      t.integer :priority, null: false, default: 0 # Higher = runs first

      # Stats
      t.integer :times_triggered, null: false, default: 0
      t.datetime :last_triggered_at

      t.timestamps
    end

    add_index :automation_rules, [:organization_id, :active]
    add_index :automation_rules, [:organization_id, :rule_type]
    add_index :automation_rules, [:job_id, :active]
    add_index :automation_rules, :trigger_event
  end
end
