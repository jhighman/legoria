# frozen_string_literal: true

# SA-03: Job Requisition - Job approval workflow
class CreateJobApprovals < ActiveRecord::Migration[8.0]
  def change
    create_table :job_approvals do |t|
      t.references :job, null: false, foreign_key: true
      t.references :approver, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending" # pending, approved, rejected
      t.text :notes
      t.integer :sequence, default: 0, null: false
      t.datetime :decided_at

      t.timestamps
    end

    add_index :job_approvals, [:job_id, :sequence]
    add_index :job_approvals, [:job_id, :status]
    add_index :job_approvals, [:approver_id, :status]
  end
end
