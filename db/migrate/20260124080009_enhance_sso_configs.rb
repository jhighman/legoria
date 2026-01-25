# frozen_string_literal: true

# Phase 6: Enhance SSO configs for SAML 2.0 and OIDC support
class EnhanceSsoConfigs < ActiveRecord::Migration[8.0]
  def change
    # SAML 2.0 specific fields
    add_column :sso_configs, :saml_entity_id, :string
    add_column :sso_configs, :saml_sso_url, :string
    add_column :sso_configs, :saml_slo_url, :string
    add_column :sso_configs, :saml_certificate, :text
    add_column :sso_configs, :saml_fingerprint, :string
    add_column :sso_configs, :saml_fingerprint_algorithm, :string, default: "sha256"

    # OIDC specific fields
    add_column :sso_configs, :oidc_discovery_url, :string
    add_column :sso_configs, :oidc_authorization_endpoint, :string
    add_column :sso_configs, :oidc_token_endpoint, :string
    add_column :sso_configs, :oidc_userinfo_endpoint, :string
    add_column :sso_configs, :oidc_jwks_uri, :string
    add_column :sso_configs, :oidc_scopes, :string, default: "openid profile email"

    # Attribute mapping
    add_column :sso_configs, :attribute_mapping, :json
    # Example: { "email": "email", "first_name": "given_name", "last_name": "family_name" }

    # Auto-provisioning
    add_column :sso_configs, :auto_provision_users, :boolean, null: false, default: false
    add_column :sso_configs, :default_role_id, :integer # Role to assign to new users

    # Domain restrictions
    add_column :sso_configs, :allowed_domains, :json # Only allow users from these email domains
    add_column :sso_configs, :enforce_sso, :boolean, null: false, default: false # Require SSO for all users

    # Debugging
    add_column :sso_configs, :debug_mode, :boolean, null: false, default: false
    add_column :sso_configs, :last_login_at, :datetime
    add_column :sso_configs, :login_count, :integer, null: false, default: 0
  end
end
