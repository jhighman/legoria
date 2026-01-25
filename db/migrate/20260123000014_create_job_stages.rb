# frozen_string_literal: true

# SA-03: Job Requisition - Job-specific stage configuration
class CreateJobStages < ActiveRecord::Migration[8.0]
  def change
    create_table :job_stages do |t|
      t.references :job, null: false, foreign_key: true
      t.references :stage, null: false, foreign_key: true
      t.integer :position, null: false
      t.boolean :required_interview, default: false, null: false
      t.bigint :scorecard_template_id # Will add FK when evaluation tables exist

      t.timestamps
    end

    add_index :job_stages, [:job_id, :position], unique: true
    add_index :job_stages, [:job_id, :stage_id], unique: true
  end
end
