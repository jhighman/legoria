# frozen_string_literal: true

# SA-06: Interview - Interview kits with question sets for job/stage
class CreateInterviewKits < ActiveRecord::Migration[8.0]
  def change
    create_table :interview_kits do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :job, foreign_key: true
      t.references :stage, foreign_key: true

      # Kit details
      t.string :name, null: false
      t.text :description
      t.string :interview_type # phone_screen, video, onsite, panel, technical, cultural_fit

      # Instructions
      t.text :introduction_notes
      t.text :closing_notes

      # Status
      t.boolean :active, null: false, default: true
      t.boolean :is_default, null: false, default: false

      t.timestamps
    end

    add_index :interview_kits, [:organization_id, :name]
    add_index :interview_kits, [:organization_id, :active]
    add_index :interview_kits, [:organization_id, :job_id]
    add_index :interview_kits, [:organization_id, :interview_type]
  end
end
