# frozen_string_literal: true

# SA-07: Evaluation - Individual responses within a scorecard
class CreateScorecardResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :scorecard_responses do |t|
      t.references :scorecard, null: false, foreign_key: true
      t.references :scorecard_template_item, null: false, foreign_key: true

      # Response values (only one populated based on item_type)
      t.integer :rating # For rating type
      t.boolean :yes_no_value # For yes_no type
      t.text :text_value # For text type
      t.string :select_value # For select type

      # Notes for any response
      t.text :notes

      t.timestamps
    end

    add_index :scorecard_responses, [:scorecard_id, :scorecard_template_item_id],
              unique: true, name: "idx_scorecard_responses_unique"
  end
end
