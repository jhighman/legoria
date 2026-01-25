# frozen_string_literal: true

require "test_helper"

class CalendarIntegrationTest < ActiveSupport::TestCase
  def setup
    @integration = calendar_integrations(:google_integration)
  end

  test "valid integration" do
    assert @integration.valid?
  end

  test "requires provider" do
    @integration.provider = nil
    assert_not @integration.valid?
    assert_includes @integration.errors[:provider], "can't be blank"
  end

  test "requires valid provider" do
    @integration.provider = "invalid_provider"
    assert_not @integration.valid?
    assert_includes @integration.errors[:provider], "is not included in the list"
  end

  test "unique provider per user" do
    duplicate = CalendarIntegration.new(
      user: @integration.user,
      provider: @integration.provider,
      calendar_id: "secondary"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:provider], "integration already exists"
  end

  # Provider helpers
  test "google? returns true for google provider" do
    assert @integration.google?
    assert_not @integration.outlook?
    assert_not @integration.apple?
  end

  test "outlook? returns true for outlook provider" do
    outlook = calendar_integrations(:outlook_integration)
    assert outlook.outlook?
    assert_not outlook.google?
  end

  # Token management
  test "token_expired? returns true when expired" do
    expired = calendar_integrations(:expired_integration)
    assert expired.token_expired?
    assert_not @integration.token_expired?
  end

  test "token_expiring_soon? returns true when expiring within 5 minutes" do
    @integration.token_expires_at = 3.minutes.from_now
    assert @integration.token_expiring_soon?
  end

  test "needs_refresh? returns true when expired or expiring soon" do
    expired = calendar_integrations(:expired_integration)
    assert expired.needs_refresh?

    @integration.token_expires_at = 3.minutes.from_now
    assert @integration.needs_refresh?

    @integration.token_expires_at = 1.hour.from_now
    assert_not @integration.needs_refresh?
  end

  # Activation methods
  test "activate! sets active to true and clears error" do
    inactive = calendar_integrations(:inactive_integration)
    inactive.sync_error = "Some error"
    inactive.activate!
    assert inactive.active?
    assert_nil inactive.sync_error
  end

  test "deactivate! sets active to false" do
    @integration.deactivate!
    assert_not @integration.active?
  end

  test "deactivate_with_error! sets active to false and records error" do
    @integration.deactivate_with_error!("Connection failed")
    assert_not @integration.active?
    assert_equal "Connection failed", @integration.sync_error
  end

  # Sync tracking
  test "mark_synced! updates last_synced_at and clears error" do
    @integration.sync_error = "Previous error"
    @integration.mark_synced!
    assert_not_nil @integration.last_synced_at
    assert_nil @integration.sync_error
  end

  test "mark_sync_error! records error message" do
    @integration.mark_sync_error!("API rate limit")
    assert_equal "API rate limit", @integration.sync_error
  end

  test "recently_synced? returns true when synced within window" do
    @integration.last_synced_at = 5.minutes.ago
    assert @integration.recently_synced?
    assert @integration.recently_synced?(within: 10.minutes)
    assert_not @integration.recently_synced?(within: 3.minutes)
  end

  # Status helpers
  test "healthy? returns true when active, not expired, no errors" do
    assert @integration.healthy?
  end

  test "healthy? returns false when inactive" do
    inactive = calendar_integrations(:inactive_integration)
    assert_not inactive.healthy?
  end

  test "healthy? returns false when expired" do
    expired = calendar_integrations(:expired_integration)
    assert_not expired.healthy?
  end

  test "status returns appropriate string" do
    assert_equal "connected", @integration.status
    assert_equal "inactive", calendar_integrations(:inactive_integration).status
    assert_equal "error", calendar_integrations(:expired_integration).status # has sync_error
  end

  test "provider_label returns human-readable name" do
    assert_equal "Google Calendar", @integration.provider_label
    assert_equal "Microsoft Outlook", calendar_integrations(:outlook_integration).provider_label
  end

  # Scopes
  test "active scope returns only active integrations" do
    active = CalendarIntegration.active
    active.each { |i| assert i.active? }
  end

  test "expired scope returns only expired tokens" do
    expired = CalendarIntegration.expired
    expired.each { |i| assert i.token_expires_at < Time.current }
  end
end
