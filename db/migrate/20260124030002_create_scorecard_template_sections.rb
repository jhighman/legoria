# frozen_string_literal: true

# SA-07: Evaluation - Sections within a scorecard template
class CreateScorecardTemplateSections < ActiveRecord::Migration[8.0]
  def change
    create_table :scorecard_template_sections do |t|
      t.references :scorecard_template, null: false, foreign_key: true

      t.string :name, null: false
      t.string :section_type, null: false, default: "competencies" # competencies, questions, overall
      t.text :description
      t.integer :position, null: false, default: 0
      t.integer :weight, default: 100 # percentage weight for scoring
      t.boolean :required, null: false, default: true

      t.timestamps
    end

    add_index :scorecard_template_sections, [:scorecard_template_id, :position]
  end
end
