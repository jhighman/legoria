# frozen_string_literal: true

# SA-02: Organization Management - Pipeline stage definitions
class CreateStages < ActiveRecord::Migration[8.0]
  def change
    create_table :stages do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :stage_type, null: false # applied, screening, interview, offer, hired, rejected
      t.integer :position, null: false
      t.boolean :is_terminal, default: false, null: false
      t.boolean :is_default, default: false, null: false
      t.string :color

      t.timestamps
    end

    add_index :stages, [:organization_id, :position]
    add_index :stages, [:organization_id, :stage_type]
    add_index :stages, [:organization_id, :is_default], where: "is_default = true"
  end
end
