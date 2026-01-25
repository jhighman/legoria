# frozen_string_literal: true

# SA-04: Candidate - Notes on candidates
class CreateCandidateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :candidate_notes do |t|
      t.references :candidate, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.string :visibility, null: false, default: "team" # private, team, all
      t.boolean :pinned, default: false, null: false

      t.timestamps
    end

    add_index :candidate_notes, [:candidate_id, :pinned]
    add_index :candidate_notes, [:candidate_id, :visibility]
  end
end
