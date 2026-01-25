# frozen_string_literal: true

# SA-07: Evaluation - Individual items within a scorecard section
class CreateScorecardTemplateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :scorecard_template_items do |t|
      t.references :scorecard_template_section, null: false, foreign_key: true

      t.string :name, null: false
      t.string :item_type, null: false, default: "rating" # rating, yes_no, text, select
      t.text :guidance
      t.integer :rating_scale, default: 5 # 1-5, 1-10, etc.
      t.json :options, default: [] # For select type items
      t.integer :position, null: false, default: 0
      t.boolean :required, null: false, default: true

      t.timestamps
    end

    add_index :scorecard_template_items, [:scorecard_template_section_id, :position],
              name: "idx_template_items_on_section_and_position"
  end
end
