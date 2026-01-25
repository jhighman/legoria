# frozen_string_literal: true

# SA-03: Job Requisition - Job board posting tracking
class CreateJobBoardPostings < ActiveRecord::Migration[8.0]
  def change
    create_table :job_board_postings do |t|
      t.references :job, null: false, foreign_key: true
      t.string :board_name, null: false
      t.string :external_id
      t.string :external_url
      t.string :status, null: false, default: "pending" # pending, active, expired, removed, error
      t.datetime :posted_at
      t.datetime :expires_at
      t.datetime :removed_at
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :job_board_postings, [:job_id, :board_name]
    add_index :job_board_postings, [:job_id, :status]
    add_index :job_board_postings, :external_id
  end
end
