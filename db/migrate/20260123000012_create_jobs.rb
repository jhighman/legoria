# frozen_string_literal: true

# SA-03: Job Requisition - Job aggregate root
class CreateJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :jobs do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :department, foreign_key: true
      t.references :hiring_manager, foreign_key: { to_table: :users }
      t.references :recruiter, foreign_key: { to_table: :users }

      # Content
      t.string :title, null: false
      t.text :description
      t.text :requirements
      t.text :internal_notes

      # Location
      t.string :location
      t.string :location_type, null: false, default: "onsite" # onsite, remote, hybrid

      # Employment
      t.string :employment_type, null: false, default: "full_time" # full_time, part_time, contract, intern

      # Compensation (stored in cents)
      t.integer :salary_min
      t.integer :salary_max
      t.string :salary_currency, default: "USD"
      t.boolean :salary_visible, default: false, null: false

      # Status
      t.string :status, null: false, default: "draft" # draft, pending_approval, open, on_hold, closed
      t.datetime :opened_at
      t.datetime :closed_at
      t.string :close_reason # filled, cancelled, on_hold

      # Headcount
      t.integer :headcount, default: 1, null: false
      t.integer :filled_count, default: 0, null: false

      # External reference
      t.string :remote_id

      t.datetime :discarded_at
      t.timestamps
    end

    add_index :jobs, [:organization_id, :status]
    add_index :jobs, [:organization_id, :department_id]
    add_index :jobs, :discarded_at
    add_index :jobs, [:organization_id, :remote_id], unique: true, where: "remote_id IS NOT NULL"
  end
end
