# frozen_string_literal: true

# Phase 3: Self-scheduling time slots for candidates
class CreateInterviewSelfSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :interview_self_schedules do |t|
      t.references :interview, null: false, foreign_key: true

      # Scheduling window
      t.datetime :scheduling_starts_at, null: false
      t.datetime :scheduling_ends_at, null: false

      # Available slots (JSON array of datetime ranges)
      t.json :available_slots

      # Settings
      t.integer :slot_duration_minutes, null: false, default: 60
      t.integer :buffer_minutes, null: false, default: 15
      t.integer :max_slots_per_day, default: 3
      t.string :timezone, null: false, default: "UTC"

      # Instructions for candidate
      t.text :instructions

      # Status
      t.string :status, null: false, default: "pending" # pending, scheduled, expired, cancelled
      t.datetime :selected_slot
      t.datetime :scheduled_at

      # Token for candidate access
      t.string :token, null: false

      t.timestamps
    end

    add_index :interview_self_schedules, :token, unique: true
    add_index :interview_self_schedules, [:interview_id, :status]
  end
end
