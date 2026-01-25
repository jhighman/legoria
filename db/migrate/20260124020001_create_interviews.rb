# frozen_string_literal: true

# SA-06: Interview - Interview scheduling and management
class CreateInterviews < ActiveRecord::Migration[8.0]
  def change
    create_table :interviews do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :application, null: false, foreign_key: true
      t.references :job, null: false, foreign_key: true
      t.references :scheduled_by, null: false, foreign_key: { to_table: :users }

      # Interview details
      t.string :interview_type, null: false # phone_screen, video, onsite, panel, technical
      t.string :status, null: false, default: "scheduled" # scheduled, confirmed, completed, cancelled, no_show
      t.string :title, null: false

      # Scheduling
      t.datetime :scheduled_at, null: false
      t.integer :duration_minutes, null: false, default: 60
      t.string :timezone, null: false, default: "UTC"

      # Location
      t.string :location
      t.string :video_meeting_url
      t.text :instructions

      # Completion
      t.datetime :confirmed_at
      t.datetime :completed_at
      t.datetime :cancelled_at
      t.string :cancellation_reason

      # Soft delete
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :interviews, [:organization_id, :scheduled_at]
    add_index :interviews, [:organization_id, :status]
    add_index :interviews, [:application_id, :status]
    add_index :interviews, [:job_id, :scheduled_at]
    add_index :interviews, :discarded_at
  end
end
