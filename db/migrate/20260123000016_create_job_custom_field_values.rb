# frozen_string_literal: true

# SA-03: Job Requisition - Custom field values for jobs
class CreateJobCustomFieldValues < ActiveRecord::Migration[8.0]
  def change
    create_table :job_custom_field_values do |t|
      t.references :job, null: false, foreign_key: true
      t.references :custom_field, null: false, foreign_key: true
      t.text :value

      t.timestamps
    end

    add_index :job_custom_field_values, [:job_id, :custom_field_id], unique: true
  end
end
