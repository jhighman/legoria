# frozen_string_literal: true

# Phase 4: Offer approval workflow
class CreateOfferApprovals < ActiveRecord::Migration[8.0]
  def change
    create_table :offer_approvals do |t|
      t.references :offer, null: false, foreign_key: true
      t.references :approver, null: false, foreign_key: { to_table: :users }

      # Approval details
      t.integer :sequence, null: false, default: 1 # Order in approval chain
      t.string :status, null: false, default: "pending" # pending, approved, rejected
      t.text :comments

      # Timestamps
      t.datetime :requested_at
      t.datetime :responded_at

      t.timestamps
    end

    add_index :offer_approvals, [:offer_id, :sequence]
    add_index :offer_approvals, [:approver_id, :status]
  end
end
