# frozen_string_literal: true

# SA-04: Candidate - Custom field values
class CreateCandidateCustomFieldValues < ActiveRecord::Migration[8.0]
  def change
    create_table :candidate_custom_field_values do |t|
      t.references :candidate, null: false, foreign_key: true
      t.references :custom_field, null: false, foreign_key: true
      t.text :value

      t.timestamps
    end

    add_index :candidate_custom_field_values, [:candidate_id, :custom_field_id], unique: true, name: "idx_candidate_cfv_unique"
  end
end
