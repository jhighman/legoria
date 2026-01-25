# frozen_string_literal: true

# Phase 3: Responses to custom application questions
class CreateApplicationQuestionResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :application_question_responses do |t|
      t.references :application, null: false, foreign_key: true
      t.references :application_question, null: false, foreign_key: true

      # Response values (use appropriate field based on question type)
      t.text :text_value
      t.boolean :boolean_value
      t.integer :number_value
      t.date :date_value
      t.json :array_value # for multiselect

      t.timestamps
    end

    add_index :application_question_responses,
              [:application_id, :application_question_id],
              unique: true,
              name: "idx_app_question_responses_unique"
  end
end
