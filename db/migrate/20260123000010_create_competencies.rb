# frozen_string_literal: true

# SA-02: Organization Management - Competency definitions for evaluation
class CreateCompetencies < ActiveRecord::Migration[8.0]
  def change
    create_table :competencies do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :description
      t.string :category # technical, behavioral, cultural, role_specific
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :competencies, [:organization_id, :category]
    add_index :competencies, [:organization_id, :active]
  end
end
