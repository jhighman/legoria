# frozen_string_literal: true

# Phase 5: Add intelligence features to existing talent pools
class EnhanceTalentPoolsForPhase5 < ActiveRecord::Migration[8.0]
  def change
    # Add Phase 5 columns to talent_pools
    add_column :talent_pools, :pool_type, :string, null: false, default: "manual"
    add_reference :talent_pools, :saved_search, foreign_key: true
    add_column :talent_pools, :active, :boolean, null: false, default: true
    add_column :talent_pools, :color, :string
    add_column :talent_pools, :candidates_count, :integer, null: false, default: 0

    add_index :talent_pools, [:organization_id, :active]
    add_index :talent_pools, [:organization_id, :pool_type]

    # Add Phase 5 columns to talent_pool_members
    add_column :talent_pool_members, :source, :string, null: false, default: "manual"
    add_column :talent_pool_members, :updated_at, :datetime

    # Backfill updated_at with created_at for existing records
    reversible do |dir|
      dir.up do
        execute "UPDATE talent_pool_members SET updated_at = created_at WHERE updated_at IS NULL"
      end
    end
  end
end
