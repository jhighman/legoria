# frozen_string_literal: true

# SA-03: Job Requisition - Reusable job templates
class CreateJobTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :job_templates do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :department, foreign_key: true

      t.string :name, null: false
      t.string :title, null: false
      t.text :description
      t.text :requirements
      t.string :location_type, null: false, default: "onsite"
      t.string :employment_type, null: false, default: "full_time"
      t.integer :salary_min
      t.integer :salary_max
      t.string :salary_currency, default: "USD"
      t.integer :default_headcount, default: 1, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :job_templates, [:organization_id, :name], unique: true
    add_index :job_templates, [:organization_id, :active]
  end
end
