# frozen_string_literal: true

# SA-04: Candidate - Resume file storage and parsing
class CreateResumes < ActiveRecord::Migration[8.0]
  def change
    create_table :resumes do |t|
      t.references :candidate, null: false, foreign_key: true

      # File metadata
      t.string :filename, null: false
      t.string :content_type, null: false
      t.integer :file_size, null: false
      t.string :storage_key, null: false

      # Parsed content
      t.text :raw_text
      t.json :parsed_data, default: {}
      t.boolean :primary, default: false, null: false
      t.datetime :parsed_at

      t.timestamps
    end

    add_index :resumes, [:candidate_id, :primary], where: '"primary" = true'
    add_index :resumes, :storage_key, unique: true
  end
end
