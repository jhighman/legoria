# frozen_string_literal: true

# SA-04: Candidate - Talent pool management
class CreateTalentPools < ActiveRecord::Migration[8.0]
  def change
    create_table :talent_pools do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.boolean :shared, default: true, null: false

      t.timestamps
    end

    add_index :talent_pools, [:organization_id, :name]

    create_table :talent_pool_members do |t|
      t.references :talent_pool, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true
      t.references :added_by, foreign_key: { to_table: :users }
      t.text :notes

      t.datetime :created_at, null: false
    end

    add_index :talent_pool_members, [:talent_pool_id, :candidate_id], unique: true
  end
end
