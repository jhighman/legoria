# frozen_string_literal: true

require "test_helper"

class IntegrationTest < ActiveSupport::TestCase
  def setup
    @integration = integrations(:indeed_integration)
  end

  # Validations
  test "valid integration" do
    assert @integration.valid?
  end

  test "requires integration_type" do
    @integration.integration_type = nil
    assert_not @integration.valid?
    assert_includes @integration.errors[:integration_type], "can't be blank"
  end

  test "validates integration_type inclusion" do
    @integration.integration_type = "invalid_type"
    assert_not @integration.valid?
    assert_includes @integration.errors[:integration_type], "is not included in the list"
  end

  test "requires provider" do
    @integration.provider = nil
    assert_not @integration.valid?
    assert_includes @integration.errors[:provider], "can't be blank"
  end

  test "validates provider for integration type" do
    @integration.integration_type = "job_board"
    @integration.provider = "checkr" # checkr is for background_check
    assert_not @integration.valid?
    assert_includes @integration.errors[:provider], "is not valid for job_board"
  end

  test "requires name" do
    @integration.name = nil
    assert_not @integration.valid?
    assert_includes @integration.errors[:name], "can't be blank"
  end

  # Associations
  test "belongs to organization" do
    assert_respond_to @integration, :organization
    assert_equal organizations(:acme), @integration.organization
  end

  test "belongs to created_by user" do
    assert_respond_to @integration, :created_by
    assert_equal users(:admin), @integration.created_by
  end

  test "has many integration_logs" do
    assert_respond_to @integration, :integration_logs
    assert @integration.integration_logs.count >= 0
  end

  # Scopes
  test "active scope returns active integrations" do
    active = Integration.active
    assert active.include?(@integration)
    assert_not active.include?(integrations(:disabled_integration))
  end

  test "by_type scope filters by integration_type" do
    job_boards = Integration.by_type("job_board")
    assert job_boards.include?(@integration)
    assert_not job_boards.include?(integrations(:checkr_integration))
  end

  # Status methods
  test "active? returns true for active status" do
    @integration.status = "active"
    assert @integration.active?
  end

  test "pending? returns true for pending status" do
    @integration.status = "pending"
    assert @integration.pending?
  end

  test "disabled? returns true for disabled status" do
    @integration.status = "disabled"
    assert @integration.disabled?
  end

  # Token methods
  test "token_expired? returns false when no expiry" do
    @integration.token_expires_at = nil
    assert_not @integration.token_expired?
  end

  test "token_expired? returns true when expired" do
    @integration.token_expires_at = 1.hour.ago
    assert @integration.token_expired?
  end

  test "token_expiring_soon? returns true when about to expire" do
    @integration.token_expires_at = 3.minutes.from_now
    assert @integration.token_expiring_soon?
  end

  # Workflow methods
  test "activate! sets status to active" do
    integration = integrations(:workday_integration)
    assert_equal "pending", integration.status
    integration.activate!
    assert_equal "active", integration.status
    assert_not_nil integration.last_sync_at
  end

  test "deactivate! sets status to disabled" do
    @integration.deactivate!
    assert_equal "disabled", @integration.status
  end

  test "mark_error! sets status and message" do
    @integration.mark_error!("Connection failed")
    assert_equal "error", @integration.status
    assert_equal "Connection failed", @integration.last_error
  end

  # Logging
  test "log_sync creates integration log" do
    assert_difference -> { @integration.integration_logs.count } do
      @integration.log_sync("sync_jobs", resource_type: "Job", success: true)
    end
  end
end
