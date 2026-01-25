# frozen_string_literal: true

# Phase 6: Enhance job board postings with integration tracking
class EnhanceJobBoardPostings < ActiveRecord::Migration[8.0]
  def change
    # Link to integration configuration
    add_reference :job_board_postings, :organization, null: true, foreign_key: true
    add_reference :job_board_postings, :integration, null: true, foreign_key: true
    add_reference :job_board_postings, :posted_by, null: true, foreign_key: { to_table: :users }

    # Sync tracking
    add_column :job_board_postings, :last_synced_at, :datetime
    add_column :job_board_postings, :last_error, :text

    # Stats from job board (if available)
    add_column :job_board_postings, :views_count, :integer, default: 0
    add_column :job_board_postings, :clicks_count, :integer, default: 0
    add_column :job_board_postings, :applications_count, :integer, default: 0

    add_index :job_board_postings, [:organization_id, :status]
  end
end
