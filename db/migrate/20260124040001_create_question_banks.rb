# frozen_string_literal: true

# SA-06: Interview - Question bank for behavioral/technical/situational questions
class CreateQuestionBanks < ActiveRecord::Migration[8.0]
  def change
    create_table :question_banks do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :competency, foreign_key: true

      # Question content
      t.text :question, null: false
      t.text :guidance

      # Classification
      t.string :question_type, null: false # behavioral, technical, situational, cultural
      t.string :difficulty # easy, medium, hard
      t.string :tags # comma-separated or JSON

      # Usage tracking
      t.integer :usage_count, null: false, default: 0

      # Status
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :question_banks, [:organization_id, :question_type]
    add_index :question_banks, [:organization_id, :active]
    add_index :question_banks, [:organization_id, :competency_id]
  end
end
