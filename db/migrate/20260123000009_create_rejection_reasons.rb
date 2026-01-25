# frozen_string_literal: true

# SA-02: Organization Management - Rejection reason catalog
class CreateRejectionReasons < ActiveRecord::Migration[8.0]
  def change
    create_table :rejection_reasons do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :category, null: false # not_qualified, timing, compensation, culture_fit, withdrew, other
      t.boolean :requires_notes, default: false, null: false
      t.boolean :active, default: true, null: false
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :rejection_reasons, [:organization_id, :category]
    add_index :rejection_reasons, [:organization_id, :active]
  end
end
