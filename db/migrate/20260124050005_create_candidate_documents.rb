# frozen_string_literal: true

# Phase 3: Additional candidate documents (beyond resume)
class CreateCandidateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :candidate_documents do |t|
      t.references :candidate, null: false, foreign_key: true
      t.references :application, foreign_key: true # optional, can be application-specific

      # Document info
      t.string :name, null: false
      t.string :document_type, null: false # resume, cover_letter, portfolio, transcript, certification, reference, other
      t.text :description

      # File is stored via Active Storage, this tracks metadata
      t.string :original_filename
      t.string :content_type
      t.integer :file_size

      # Status
      t.boolean :visible_to_employer, null: false, default: true

      t.timestamps
    end

    add_index :candidate_documents, [:candidate_id, :document_type]
  end
end
