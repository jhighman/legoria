# frozen_string_literal: true

# SA-06: Interview - Links interview kits to questions
class CreateInterviewKitQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :interview_kit_questions do |t|
      t.references :interview_kit, null: false, foreign_key: true
      t.references :question_bank, foreign_key: true

      # Custom question (alternative to question_bank reference)
      t.text :question
      t.text :guidance

      # Ordering and timing
      t.integer :position, null: false, default: 0
      t.integer :time_allocation # minutes

      t.timestamps
    end

    add_index :interview_kit_questions, [:interview_kit_id, :position]
  end
end
