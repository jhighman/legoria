# frozen_string_literal: true

# SA-04: Candidate - Source tracking
class CreateCandidateSources < ActiveRecord::Migration[8.0]
  def change
    create_table :candidate_sources do |t|
      t.references :candidate, null: false, foreign_key: true
      t.string :source_type, null: false # direct_apply, recruiter, referral, agency, job_board, linkedin
      t.string :source_detail
      t.references :source_job, foreign_key: { to_table: :jobs }

      t.datetime :created_at, null: false
    end

    add_index :candidate_sources, [:candidate_id, :source_type]
  end
end
