# frozen_string_literal: true

# SA-07: Evaluation - Scorecard templates for structured feedback
class CreateScorecardTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :scorecard_templates do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :job, foreign_key: true
      t.references :stage, foreign_key: true

      t.string :name, null: false
      t.string :interview_type # phone_screen, video, onsite, technical, etc.
      t.text :description

      t.boolean :active, null: false, default: true
      t.boolean :is_default, null: false, default: false

      t.timestamps
    end

    add_index :scorecard_templates, [:organization_id, :active]
    add_index :scorecard_templates, [:organization_id, :is_default]
    add_index :scorecard_templates, [:job_id, :stage_id]
  end
end
