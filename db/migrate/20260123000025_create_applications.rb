# frozen_string_literal: true

# SA-05: Application Pipeline - Application aggregate root
class CreateApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :applications do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :job, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true
      t.references :current_stage, null: false, foreign_key: { to_table: :stages }

      # Status
      t.string :status, null: false, default: "active" # active, hired, rejected, withdrawn

      # Rejection
      t.references :rejection_reason, foreign_key: true
      t.text :rejection_notes

      # Source
      t.string :source_type, null: false # direct_apply, recruiter, referral, agency, job_board
      t.string :source_detail

      # Timestamps
      t.datetime :applied_at, null: false
      t.datetime :hired_at
      t.datetime :rejected_at
      t.datetime :withdrawn_at

      # Evaluation
      t.integer :rating # 1-5
      t.boolean :starred, default: false, null: false

      # Activity
      t.datetime :last_activity_at, null: false

      t.datetime :discarded_at
      t.timestamps
    end

    # Prevent duplicate applications
    add_index :applications, [:job_id, :candidate_id], unique: true
    add_index :applications, [:organization_id, :status]
    add_index :applications, [:job_id, :status]
    add_index :applications, [:job_id, :current_stage_id]
    add_index :applications, :discarded_at
    add_index :applications, [:organization_id, :last_activity_at]
    add_index :applications, [:organization_id, :starred], where: "starred = true"
  end
end
