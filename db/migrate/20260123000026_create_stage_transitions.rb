# frozen_string_literal: true

# SA-05: Application Pipeline - Immutable stage transition log
class CreateStageTransitions < ActiveRecord::Migration[8.0]
  def change
    create_table :stage_transitions do |t|
      t.references :application, null: false, foreign_key: true
      t.references :from_stage, foreign_key: { to_table: :stages }
      t.references :to_stage, null: false, foreign_key: { to_table: :stages }
      t.references :moved_by, foreign_key: { to_table: :users }
      t.text :notes
      t.integer :duration_hours # Time spent in previous stage

      # Immutable - only created_at, no updated_at
      t.datetime :created_at, null: false
    end

    add_index :stage_transitions, [:application_id, :created_at]
  end
end
