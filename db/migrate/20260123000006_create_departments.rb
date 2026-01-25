# frozen_string_literal: true

# SA-02: Organization Management - Department hierarchy
class CreateDepartments < ActiveRecord::Migration[8.0]
  def change
    create_table :departments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :departments }
      t.string :name, null: false
      t.string :code
      t.integer :position, default: 0, null: false
      t.references :default_hiring_manager, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :departments, [:organization_id, :name]
    add_index :departments, [:organization_id, :code], unique: true, where: "code IS NOT NULL"
  end
end
