# frozen_string_literal: true

require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
  end

  # Generation
  test "generate creates valid api key" do
    api_key, plain_key = ApiKey.generate(
      user: @user,
      name: "Test API Key",
      scopes: ["read"]
    )

    assert api_key.persisted?
    assert_equal "Test API Key", api_key.name
    assert_equal @user, api_key.user
    assert_equal @user.organization, api_key.organization
    assert_not_nil plain_key
    assert_equal 64, plain_key.length # hex(32)
    assert_equal plain_key[0..7], api_key.key_prefix
  end

  test "generate with expiry sets expires_at" do
    api_key, _ = ApiKey.generate(
      user: @user,
      name: "Expiring Key",
      expires_at: 30.days.from_now
    )

    assert api_key.persisted?
    assert_not_nil api_key.expires_at
  end

  # Authentication
  test "authenticate finds valid key" do
    api_key, plain_key = ApiKey.generate(user: @user, name: "Test")

    found = ApiKey.authenticate(plain_key)

    assert_equal api_key, found
    assert_not_nil found.last_used_at
  end

  test "authenticate returns nil for invalid key" do
    found = ApiKey.authenticate("invalid_key_123")

    assert_nil found
  end

  test "authenticate returns nil for revoked key" do
    api_key, plain_key = ApiKey.generate(user: @user, name: "Test")
    api_key.revoke!

    found = ApiKey.authenticate(plain_key)

    assert_nil found
  end

  test "authenticate returns nil for expired key" do
    api_key, plain_key = ApiKey.generate(user: @user, name: "Test", expires_at: 1.day.ago)

    found = ApiKey.authenticate(plain_key)

    assert_nil found
  end

  # Status methods
  test "active? returns true for valid key" do
    api_key, _ = ApiKey.generate(user: @user, name: "Test")

    assert api_key.active?
  end

  test "active? returns false for revoked key" do
    api_key, _ = ApiKey.generate(user: @user, name: "Test")
    api_key.revoke!

    assert_not api_key.active?
  end

  test "active? returns false for expired key" do
    api_key, _ = ApiKey.generate(user: @user, name: "Test", expires_at: 1.hour.ago)

    assert_not api_key.active?
  end

  test "revoke! sets revoked_at" do
    api_key, _ = ApiKey.generate(user: @user, name: "Test")
    api_key.revoke!

    assert api_key.revoked?
    assert_not_nil api_key.revoked_at
  end

  # Scopes
  test "has_scope? checks scope membership" do
    api_key, _ = ApiKey.generate(user: @user, name: "Test", scopes: ["read", "write"])

    assert api_key.has_scope?("read")
    assert api_key.has_scope?(:write)
    assert_not api_key.has_scope?("admin")
  end

  # IP restrictions
  test "ip_allowed? returns true when no restrictions" do
    api_key, _ = ApiKey.generate(user: @user, name: "Test")

    assert api_key.ip_allowed?("1.2.3.4")
  end

  test "ip_allowed? checks allowed IPs" do
    api_key, _ = ApiKey.generate(user: @user, name: "Test")
    api_key.update!(allowed_ips: ["1.2.3.4", "5.6.7.8"])

    assert api_key.ip_allowed?("1.2.3.4")
    assert api_key.ip_allowed?("5.6.7.8")
    assert_not api_key.ip_allowed?("9.10.11.12")
  end

  test "ip_allowed? supports CIDR notation" do
    api_key, _ = ApiKey.generate(user: @user, name: "Test")
    api_key.update!(allowed_ips: ["10.0.0.0/8"])

    assert api_key.ip_allowed?("10.1.2.3")
    assert api_key.ip_allowed?("10.255.255.255")
    assert_not api_key.ip_allowed?("11.0.0.1")
  end

  test "validates allowed_ips format" do
    api_key, _ = ApiKey.generate(user: @user, name: "Test")
    api_key.allowed_ips = ["not-an-ip"]

    assert_not api_key.valid?
    assert_includes api_key.errors[:allowed_ips], "contains invalid IP address: not-an-ip"
  end

  # Rate limiting
  test "rate_limited? returns nil when under limit" do
    api_key, _ = ApiKey.generate(user: @user, name: "Test")
    api_key.update!(
      rate_limit_per_minute: 60,
      requests_this_minute: 30,
      minute_reset_at: 1.minute.from_now
    )

    assert_nil api_key.rate_limited?
  end

  test "rate_limited? returns :minute_limit when exceeded" do
    api_key, _ = ApiKey.generate(user: @user, name: "Test")
    api_key.update!(
      rate_limit_per_minute: 60,
      requests_this_minute: 60,
      minute_reset_at: 1.minute.from_now
    )

    assert_equal :minute_limit, api_key.rate_limited?
  end

  test "rate_limit_status returns current counts" do
    api_key, _ = ApiKey.generate(user: @user, name: "Test")
    api_key.update!(
      rate_limit_per_minute: 60,
      rate_limit_per_hour: 1000,
      rate_limit_per_day: 10000,
      requests_this_minute: 5,
      requests_this_hour: 50,
      requests_today: 500,
      minute_reset_at: 1.minute.from_now,
      hour_reset_at: 1.hour.from_now,
      day_reset_at: 1.day.from_now
    )

    status = api_key.rate_limit_status

    assert_equal 5, status[:minute][:used]
    assert_equal 60, status[:minute][:limit]
    assert_equal 50, status[:hour][:used]
    assert_equal 1000, status[:hour][:limit]
    assert_equal 500, status[:day][:used]
    assert_equal 10000, status[:day][:limit]
  end

  # Scopes
  test "active scope excludes revoked keys" do
    api_key, _ = ApiKey.generate(user: @user, name: "Test")
    revoked, _ = ApiKey.generate(user: @user, name: "Revoked")
    revoked.revoke!

    active = ApiKey.active

    assert active.include?(api_key)
    assert_not active.include?(revoked)
  end

  test "active scope excludes expired keys" do
    api_key, _ = ApiKey.generate(user: @user, name: "Test")
    expired, _ = ApiKey.generate(user: @user, name: "Expired", expires_at: 1.hour.ago)

    active = ApiKey.active

    assert active.include?(api_key)
    assert_not active.include?(expired)
  end
end
