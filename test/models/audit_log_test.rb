# frozen_string_literal: true

require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    @user = users(:admin)
    @job = jobs(:open_job)

    # Set current context
    Current.organization = @organization
    Current.user = @user
    Current.ip_address = "127.0.0.1"
    Current.request_id = "test-request-123"
  end

  def teardown
    Current.reset
  end

  # Immutability tests
  test "cannot update audit log" do
    audit_log = AuditLog.create!(
      organization: @organization,
      user: @user,
      action: "test.created",
      auditable: @job
    )

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      audit_log.update!(action: "test.updated")
    end
  end

  test "cannot delete audit log" do
    audit_log = AuditLog.create!(
      organization: @organization,
      user: @user,
      action: "test.created",
      auditable: @job
    )

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      audit_log.destroy!
    end
  end

  # Creation tests
  test "creates audit log with log! class method" do
    assert_difference("AuditLog.count") do
      AuditLog.log!(
        action: "job.created",
        auditable: @job,
        metadata: { title: @job.title }
      )
    end

    audit_log = AuditLog.last
    assert_equal "job.created", audit_log.action
    assert_equal @job, audit_log.auditable
    assert_equal @user, audit_log.user
    assert_equal @organization, audit_log.organization
    assert_equal "127.0.0.1", audit_log.ip_address
    assert_equal "test-request-123", audit_log.request_id
  end

  test "log class method does not raise on failure" do
    # Try to create with invalid auditable (nil)
    result = AuditLog.log(
      action: "test.action",
      auditable: nil,
      metadata: {}
    )

    assert_nil result
  end

  test "sanitizes sensitive fields from recorded_changes" do
    changes = {
      "password" => ["old", "new"],
      "encrypted_password" => ["hash1", "hash2"],
      "ssn" => ["111-11-1111", "222-22-2222"],
      "name" => ["John", "Jane"]
    }

    audit_log = AuditLog.log!(
      action: "test.update",
      auditable: @job,
      recorded_changes: changes
    )

    # Sensitive fields should be removed
    assert_not audit_log.recorded_changes.key?("password")
    assert_not audit_log.recorded_changes.key?("encrypted_password")
    assert_not audit_log.recorded_changes.key?("ssn")
    # Non-sensitive fields should remain
    assert audit_log.recorded_changes.key?("name")
  end

  # Display helpers
  test "action_label returns titleized action name" do
    audit_log = AuditLog.new(action: "job.status_changed")
    assert_equal "Status Changed", audit_log.action_label
  end

  test "action_category returns first part of action" do
    audit_log = AuditLog.new(action: "job.status_changed")
    assert_equal "job", audit_log.action_category
  end

  test "user_display_name returns System when user is nil" do
    audit_log = AuditLog.new(user: nil)
    assert_equal "System", audit_log.user_display_name
  end

  test "user_display_name returns user name when present" do
    audit_log = AuditLog.new(user: @user)
    assert_equal @user.display_name, audit_log.user_display_name
  end

  test "recorded_changes_summary formats changes" do
    audit_log = AuditLog.new(recorded_changes: { "status" => ["draft", "open"] })
    assert_includes audit_log.recorded_changes_summary, "Status"
    assert_includes audit_log.recorded_changes_summary, "draft"
    assert_includes audit_log.recorded_changes_summary, "open"
  end

  # Scopes
  test "recent scope orders by created_at desc" do
    old_log = AuditLog.create!(
      organization: @organization,
      action: "test.old",
      auditable: @job,
      created_at: 1.day.ago
    )
    new_log = AuditLog.create!(
      organization: @organization,
      action: "test.new",
      auditable: @job,
      created_at: Time.current
    )

    logs = AuditLog.recent
    assert_equal new_log, logs.first
  end

  test "by_action scope filters by action" do
    AuditLog.create!(organization: @organization, action: "job.created", auditable: @job)
    AuditLog.create!(organization: @organization, action: "job.updated", auditable: @job)

    logs = AuditLog.by_action("job.created")
    assert logs.all? { |l| l.action == "job.created" }
  end

  test "today scope returns logs from today" do
    today_log = AuditLog.create!(
      organization: @organization,
      action: "test.today",
      auditable: @job,
      created_at: Time.current
    )

    logs = AuditLog.today
    assert_includes logs, today_log
  end
end
