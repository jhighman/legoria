# frozen_string_literal: true

# SA-01: Identity & Access - SSO configuration and identities
class CreateSsoTables < ActiveRecord::Migration[8.0]
  def change
    # SSO provider configuration per organization
    create_table :sso_configs do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :provider, null: false # saml, oidc
      t.string :issuer_url
      t.string :client_id
      t.string :client_secret
      t.json :metadata, default: {}
      t.boolean :enabled, default: false, null: false

      t.timestamps
    end

    add_index :sso_configs, [:organization_id, :provider], unique: true

    # User's SSO identity link
    create_table :sso_identities do |t|
      t.references :user, null: false, foreign_key: true
      t.references :sso_config, null: false, foreign_key: true
      t.string :provider_uid, null: false
      t.json :provider_data, default: {}
      t.datetime :last_used_at

      t.datetime :created_at, null: false
    end

    add_index :sso_identities, [:sso_config_id, :provider_uid], unique: true
  end
end
