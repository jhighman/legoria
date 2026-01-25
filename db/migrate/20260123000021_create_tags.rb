# frozen_string_literal: true

# SA-04: Candidate - Tag system for candidates
class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color

      t.datetime :created_at, null: false
    end

    add_index :tags, [:organization_id, :name], unique: true

    create_table :candidate_tags do |t|
      t.references :candidate, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.references :added_by, foreign_key: { to_table: :users }

      t.datetime :created_at, null: false
    end

    add_index :candidate_tags, [:candidate_id, :tag_id], unique: true
  end
end
