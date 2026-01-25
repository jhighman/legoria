# frozen_string_literal: true

require "test_helper"

class SsoIdentityTest < ActiveSupport::TestCase
  def setup
    @identity = sso_identities(:admin_saml_identity)
  end

  # Validations
  test "valid sso identity" do
    assert @identity.valid?
  end

  test "requires provider_uid" do
    @identity.provider_uid = nil
    assert_not @identity.valid?
    assert_includes @identity.errors[:provider_uid], "can't be blank"
  end

  test "requires unique provider_uid per sso_config" do
    duplicate = @identity.dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:provider_uid], "has already been taken"
  end

  test "allows same provider_uid for different sso_config" do
    other_config = sso_configs(:globex_saml)
    identity = SsoIdentity.new(
      user: users(:recruiter),
      sso_config: other_config,
      provider_uid: @identity.provider_uid
    )
    assert identity.valid?
  end

  # Associations
  test "belongs to user" do
    assert_respond_to @identity, :user
    assert_equal users(:admin), @identity.user
  end

  test "belongs to sso_config" do
    assert_respond_to @identity, :sso_config
    assert_equal sso_configs(:acme_saml), @identity.sso_config
  end

  # Class methods
  test "find_by_provider_uid finds identity" do
    found = SsoIdentity.find_by_provider_uid(
      sso_config: @identity.sso_config,
      uid: @identity.provider_uid
    )

    assert_equal @identity, found
  end

  test "find_by_provider_uid returns nil for unknown uid" do
    found = SsoIdentity.find_by_provider_uid(
      sso_config: @identity.sso_config,
      uid: "unknown_uid"
    )

    assert_nil found
  end

  test "link_user creates or updates identity" do
    user = users(:recruiter)
    config = sso_configs(:acme_saml)

    identity = SsoIdentity.link_user(
      user: user,
      sso_config: config,
      uid: "new_uid_123",
      provider_data: { email: "bob@example.com" }
    )

    assert identity.persisted?
    assert_equal "new_uid_123", identity.provider_uid
    assert_equal({ "email" => "bob@example.com" }, identity.provider_data)
    assert_not_nil identity.last_used_at
  end

  test "link_user updates existing identity" do
    SsoIdentity.link_user(
      user: @identity.user,
      sso_config: @identity.sso_config,
      uid: "updated_uid",
      provider_data: { new: "data" }
    )

    @identity.reload
    assert_equal "updated_uid", @identity.provider_uid
  end

  # Instance methods
  test "record_usage! updates last_used_at" do
    old_time = @identity.last_used_at
    @identity.record_usage!

    assert @identity.last_used_at > old_time
  end

  test "stale? returns true when not used for 90 days" do
    stale = sso_identities(:stale_identity)
    assert stale.stale?
  end

  test "stale? returns false for recently used identity" do
    assert_not @identity.stale?
  end

  test "stale? returns true when never used" do
    @identity.last_used_at = nil
    assert @identity.stale?
  end

  # Scopes
  test "recently_used scope returns active identities" do
    recent = SsoIdentity.recently_used
    assert recent.include?(@identity)
    assert_not recent.include?(sso_identities(:stale_identity))
  end
end
