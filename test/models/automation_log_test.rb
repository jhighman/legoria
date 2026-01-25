# frozen_string_literal: true

require "test_helper"

class AutomationLogTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
    Current.user = users(:admin)
  end

  teardown do
    Current.reset
  end

  # Validations
  test "requires status" do
    log = AutomationLog.new(
      organization: @organization,
      automation_rule: automation_rules(:knockout_rule),
      trigger_event: "application_created",
      triggered_at: Time.current
    )
    assert_not log.valid?
    assert_includes log.errors[:status], "can't be blank"
  end

  test "validates status inclusion" do
    log = automation_logs(:knockout_success)
    log.status = "invalid"
    assert_not log.valid?
    assert_includes log.errors[:status], "is not included in the list"
  end

  test "requires trigger_event" do
    log = AutomationLog.new(
      organization: @organization,
      automation_rule: automation_rules(:knockout_rule),
      status: "success",
      triggered_at: Time.current
    )
    assert_not log.valid?
    assert_includes log.errors[:trigger_event], "can't be blank"
  end

  test "requires triggered_at" do
    log = AutomationLog.new(
      organization: @organization,
      automation_rule: automation_rules(:knockout_rule),
      status: "success",
      trigger_event: "application_created"
    )
    assert_not log.valid?
    assert_includes log.errors[:triggered_at], "can't be blank"
  end

  # Status checks
  test "successful? returns true for success status" do
    log = automation_logs(:knockout_success)
    assert log.successful?
    assert_not log.failed?
    assert_not log.skipped?
  end

  test "failed? returns true for failed status" do
    log = automation_logs(:failed_log)
    assert log.failed?
    assert_not log.successful?
    assert_not log.skipped?
  end

  test "skipped? returns true for skipped status" do
    log = automation_logs(:skipped_log)
    assert log.skipped?
    assert_not log.successful?
    assert_not log.failed?
  end

  # Scopes
  test "successful scope returns success logs" do
    assert_includes AutomationLog.successful, automation_logs(:knockout_success)
    assert_not_includes AutomationLog.successful, automation_logs(:failed_log)
  end

  test "failed scope returns failed logs" do
    assert_includes AutomationLog.failed, automation_logs(:failed_log)
    assert_not_includes AutomationLog.failed, automation_logs(:knockout_success)
  end

  test "skipped scope returns skipped logs" do
    assert_includes AutomationLog.skipped, automation_logs(:skipped_log)
    assert_not_includes AutomationLog.skipped, automation_logs(:knockout_success)
  end

  test "for_application filters by application" do
    app = applications(:rejected_application)
    logs = AutomationLog.for_application(app.id)
    assert_includes logs, automation_logs(:knockout_success)
  end

  test "for_rule filters by automation rule" do
    rule = automation_rules(:knockout_rule)
    logs = AutomationLog.for_rule(rule.id)
    assert_includes logs, automation_logs(:knockout_success)
    assert_includes logs, automation_logs(:failed_log)
  end
end
