# frozen_string_literal: true

# SA-07: Evaluation - IMMUTABLE hiring decisions (no updates/deletes allowed)
class CreateHiringDecisions < ActiveRecord::Migration[8.0]
  def change
    create_table :hiring_decisions do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :application, null: false, foreign_key: true
      t.references :decided_by, null: false, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }

      # Decision
      t.string :decision, null: false # hire, reject, hold
      t.string :status, null: false, default: "pending" # pending, approved, rejected

      # Rationale
      t.text :rationale, null: false

      # For hire decisions
      t.decimal :proposed_salary, precision: 12, scale: 2
      t.string :proposed_salary_currency, default: "USD"
      t.date :proposed_start_date

      # Timestamps
      t.datetime :decided_at, null: false
      t.datetime :approved_at
      t.datetime :rejected_at

      t.timestamps
    end

    add_index :hiring_decisions, [:organization_id, :application_id]
    add_index :hiring_decisions, [:organization_id, :decision]
    add_index :hiring_decisions, [:organization_id, :status]
    # Note: decided_by_id and approved_by_id indexes are auto-created by t.references
  end
end
