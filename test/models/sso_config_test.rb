# frozen_string_literal: true

require "test_helper"

class SsoConfigTest < ActiveSupport::TestCase
  def setup
    @saml_config = sso_configs(:acme_saml)
    @oidc_config = sso_configs(:acme_oidc)
    # Set encrypted field programmatically (fixtures bypass encryption)
    @oidc_config.client_secret = "test_secret_value"
  end

  # Validations
  test "valid saml config" do
    assert @saml_config.valid?
  end

  test "valid oidc config" do
    assert @oidc_config.valid?
  end

  test "requires provider" do
    @saml_config.provider = nil
    assert_not @saml_config.valid?
    assert_includes @saml_config.errors[:provider], "can't be blank"
  end

  test "validates provider inclusion" do
    @saml_config.provider = "invalid"
    assert_not @saml_config.valid?
    assert_includes @saml_config.errors[:provider], "is not included in the list"
  end

  test "saml requires entity_id" do
    @saml_config.saml_entity_id = nil
    assert_not @saml_config.valid?
    assert_includes @saml_config.errors[:saml_entity_id], "can't be blank"
  end

  test "saml requires sso_url" do
    @saml_config.saml_sso_url = nil
    assert_not @saml_config.valid?
    assert_includes @saml_config.errors[:saml_sso_url], "can't be blank"
  end

  test "oidc requires client_id" do
    @oidc_config.client_id = nil
    assert_not @oidc_config.valid?
    assert_includes @oidc_config.errors[:client_id], "can't be blank"
  end

  test "oidc requires client_secret" do
    @oidc_config.client_secret = nil
    assert_not @oidc_config.valid?
    assert_includes @oidc_config.errors[:client_secret], "can't be blank"
  end

  test "oidc requires endpoints when no discovery url" do
    @oidc_config.oidc_discovery_url = nil
    @oidc_config.oidc_authorization_endpoint = nil
    @oidc_config.oidc_token_endpoint = nil

    assert_not @oidc_config.valid?
    assert_includes @oidc_config.errors[:oidc_authorization_endpoint], "is required when discovery URL is not provided"
  end

  test "validates allowed_domains format" do
    @saml_config.allowed_domains = ["invalid domain"]
    assert_not @saml_config.valid?
    assert_includes @saml_config.errors[:allowed_domains], "contains invalid domain: invalid domain"
  end

  # Associations
  test "belongs to organization" do
    assert_respond_to @saml_config, :organization
    assert_equal organizations(:acme), @saml_config.organization
  end

  test "has many sso_identities" do
    assert_respond_to @saml_config, :sso_identities
  end

  # Provider checks
  test "saml? returns true for saml provider" do
    assert @saml_config.saml?
    assert_not @saml_config.oidc?
  end

  test "oidc? returns true for oidc provider" do
    assert @oidc_config.oidc?
    assert_not @oidc_config.saml?
  end

  # SAML settings
  test "saml_settings returns config for saml" do
    settings = @saml_config.saml_settings

    assert_equal @saml_config.saml_entity_id, settings[:issuer]
    assert_equal @saml_config.saml_sso_url, settings[:idp_sso_target_url]
    assert_equal @saml_config.saml_slo_url, settings[:idp_slo_target_url]
    assert_equal @saml_config.saml_fingerprint, settings[:idp_cert_fingerprint]
  end

  test "saml_settings returns empty for oidc" do
    settings = @oidc_config.saml_settings
    assert_empty settings
  end

  # Attribute mapping
  test "map_attributes maps external attributes" do
    raw = { "email" => "test@example.com", "givenName" => "Test", "sn" => "User" }
    mapped = @saml_config.map_attributes(raw)

    assert_equal "test@example.com", mapped[:email]
    assert_equal "Test", mapped[:first_name]
    assert_equal "User", mapped[:last_name]
  end

  test "map_attributes returns empty for blank mapping" do
    @saml_config.attribute_mapping = nil
    mapped = @saml_config.map_attributes({ "email" => "test@example.com" })

    assert_empty mapped
  end

  # Domain restrictions
  test "email_domain_allowed? returns true when no restrictions" do
    @saml_config.allowed_domains = nil
    assert @saml_config.email_domain_allowed?("user@any.domain.com")
  end

  test "email_domain_allowed? checks domain" do
    @saml_config.allowed_domains = ["acme.example.com"]

    assert @saml_config.email_domain_allowed?("user@acme.example.com")
    assert_not @saml_config.email_domain_allowed?("user@other.com")
  end

  # Auto-provisioning
  test "should_auto_provision? checks both flags" do
    @saml_config.auto_provision_users = true
    @saml_config.enabled = true
    assert @saml_config.should_auto_provision?

    @saml_config.enabled = false
    assert_not @saml_config.should_auto_provision?
  end

  # Usage tracking
  test "record_login! increments count" do
    original_count = @saml_config.login_count

    @saml_config.record_login!

    assert_equal original_count + 1, @saml_config.login_count
    assert_not_nil @saml_config.last_login_at
  end

  # Scopes
  test "enabled scope returns enabled configs" do
    enabled = SsoConfig.enabled
    assert enabled.include?(@saml_config)
    assert_not enabled.include?(@oidc_config)
  end

  test "saml scope returns saml configs" do
    saml = SsoConfig.saml
    assert saml.include?(@saml_config)
    assert_not saml.include?(@oidc_config)
  end

  test "oidc scope returns oidc configs" do
    oidc = SsoConfig.oidc
    assert oidc.include?(@oidc_config)
    assert_not oidc.include?(@saml_config)
  end
end
