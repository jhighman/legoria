# frozen_string_literal: true

require "test_helper"

class IntegrationLogTest < ActiveSupport::TestCase
  def setup
    @log = integration_logs(:indeed_sync_success)
  end

  # Validations
  test "valid integration log" do
    assert @log.valid?
  end

  test "requires action" do
    @log.action = nil
    assert_not @log.valid?
    assert_includes @log.errors[:action], "can't be blank"
  end

  test "requires status" do
    @log.status = nil
    assert_not @log.valid?
    assert_includes @log.errors[:status], "can't be blank"
  end

  test "validates status inclusion" do
    @log.status = "invalid"
    assert_not @log.valid?
    assert_includes @log.errors[:status], "is not included in the list"
  end

  test "requires direction" do
    @log.direction = nil
    assert_not @log.valid?
    assert_includes @log.errors[:direction], "can't be blank"
  end

  test "validates direction inclusion" do
    @log.direction = "invalid"
    assert_not @log.valid?
    assert_includes @log.errors[:direction], "is not included in the list"
  end

  test "requires started_at" do
    @log.started_at = nil
    assert_not @log.valid?
    assert_includes @log.errors[:started_at], "can't be blank"
  end

  # Associations
  test "belongs to organization" do
    assert_respond_to @log, :organization
    assert_equal organizations(:acme), @log.organization
  end

  test "belongs to integration" do
    assert_respond_to @log, :integration
    assert_equal integrations(:indeed_integration), @log.integration
  end

  # Status methods
  test "success? returns true for success status" do
    assert @log.success?
    assert_not @log.failed?
  end

  test "failed? returns true for failed status" do
    failed = integration_logs(:indeed_sync_failure)
    assert failed.failed?
    assert_not failed.success?
  end

  # Scopes
  test "successful scope returns only successful logs" do
    successful = IntegrationLog.successful
    assert successful.include?(@log)
    assert_not successful.include?(integration_logs(:indeed_sync_failure))
  end

  test "failed scope returns only failed logs" do
    failed = IntegrationLog.failed
    assert_not failed.include?(@log)
    assert failed.include?(integration_logs(:indeed_sync_failure))
  end

  test "by_action scope filters by action" do
    sync_logs = IntegrationLog.by_action("sync_jobs")
    assert sync_logs.include?(@log)
    assert_not sync_logs.include?(integration_logs(:checkr_submit))
  end

  # Complete method
  test "complete! updates status and timestamps" do
    log = integration_logs(:indeed_sync_failure)
    log.complete!(
      success: true,
      records_processed: 10,
      records_created: 5,
      records_updated: 5
    )

    assert log.success?
    assert_equal 10, log.records_processed
    assert_equal 5, log.records_created
    assert_equal 5, log.records_updated
    assert_not_nil log.completed_at
  end
end
