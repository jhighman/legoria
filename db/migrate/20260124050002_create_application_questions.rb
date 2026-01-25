# frozen_string_literal: true

# Phase 3: Custom application questions per job
class CreateApplicationQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :application_questions do |t|
      t.references :job, null: false, foreign_key: true

      # Question content
      t.string :question, null: false
      t.text :description
      t.string :question_type, null: false # text, textarea, select, multiselect, yes_no, number, date, file

      # Options for select/multiselect (stored as JSON array)
      t.json :options

      # Validation
      t.boolean :required, null: false, default: false
      t.integer :min_length
      t.integer :max_length
      t.integer :min_value
      t.integer :max_value

      # Display
      t.integer :position, null: false, default: 0
      t.string :placeholder
      t.text :help_text

      # Status
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :application_questions, [:job_id, :position]
    add_index :application_questions, [:job_id, :active]
  end
end
