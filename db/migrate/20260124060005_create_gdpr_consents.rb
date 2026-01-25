# frozen_string_literal: true

# Phase 4: GDPR consent tracking for data processing
class CreateGdprConsents < ActiveRecord::Migration[8.0]
  def change
    create_table :gdpr_consents do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true

      # Consent type
      t.string :consent_type, null: false # data_processing, marketing, third_party_sharing, background_check

      # Consent details
      t.boolean :granted, null: false, default: false
      t.text :consent_text # The specific text shown to user
      t.string :consent_version # Version of consent form

      # Collection context
      t.string :collection_method # application_form, email_link, portal
      t.string :ip_address
      t.string :user_agent

      # Timestamps
      t.datetime :granted_at
      t.datetime :withdrawn_at

      t.timestamps
    end

    add_index :gdpr_consents, [:organization_id, :consent_type]
    add_index :gdpr_consents, [:candidate_id, :consent_type]
    add_index :gdpr_consents, [:organization_id, :granted]
  end
end
