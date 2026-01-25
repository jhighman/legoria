# frozen_string_literal: true

# Phase 4: EEOC voluntary self-identification data (collected post-apply)
class CreateEeocResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :eeoc_responses do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :application, null: false, foreign_key: true, index: { unique: true }

      # Voluntary disclosure (all optional)
      t.string :gender # male, female, non_binary, prefer_not_to_say
      t.string :race_ethnicity # hispanic_latino, white, black, asian, native_american, pacific_islander, two_or_more, prefer_not_to_say
      t.string :veteran_status # protected_veteran, not_veteran, prefer_not_to_say
      t.string :disability_status # yes, no, prefer_not_to_say

      # Consent tracking
      t.boolean :consent_given, null: false, default: false
      t.datetime :consent_timestamp
      t.string :consent_ip_address

      # For audit purposes
      t.string :collection_context # application, post_apply_email, offer_stage

      t.timestamps
    end

    add_index :eeoc_responses, [:organization_id, :created_at]
  end
end
