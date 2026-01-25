# frozen_string_literal: true

# Phase 5: Add search-optimized fields to candidates
class AddSearchFieldsToCandidates < ActiveRecord::Migration[8.0]
  def change
    add_column :candidates, :search_text, :text # Concatenated searchable text
    add_column :candidates, :skills_list, :text # Comma-separated skills for search
    add_column :candidates, :years_experience, :integer
    add_column :candidates, :highest_education, :string
    add_column :candidates, :last_job_title, :string
    add_column :candidates, :last_company, :string

    # Add index for full-text search (works in both SQLite and PostgreSQL)
    # For production PostgreSQL, a GIN index would be more efficient
    add_index :candidates, :search_text
  end
end
