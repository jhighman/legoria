# frozen_string_literal: true

require "test_helper"

class I9DeadlineReminderJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
  end

  teardown do
    Current.reset
  end

  test "performs successfully" do
    assert_nothing_raised do
      I9DeadlineReminderJob.perform_now
    end
  end

  test "queues notification for verifications due tomorrow" do
    verification = i9_verifications(:section1_complete)
    verification.update_column(:deadline_section2, Date.tomorrow)

    assert_enqueued_with(job: I9NotificationJob) do
      I9DeadlineReminderJob.perform_now
    end
  end

  test "creates audit log for overdue verifications" do
    verification = i9_verifications(:section1_complete)
    verification.update_columns(
      deadline_section2: Date.yesterday,
      late_completion: false
    )

    assert_difference "AuditLog.count", 1 do
      I9DeadlineReminderJob.perform_now
    end
  end

  test "marks overdue verifications as late" do
    verification = i9_verifications(:section1_complete)
    verification.update_columns(
      deadline_section2: Date.yesterday,
      late_completion: false
    )

    I9DeadlineReminderJob.perform_now

    verification.reload
    assert verification.late_completion?
  end

  test "skips already late verifications" do
    verification = i9_verifications(:section1_complete)
    verification.update_columns(
      deadline_section2: Date.yesterday,
      late_completion: true
    )

    assert_no_difference "AuditLog.count" do
      I9DeadlineReminderJob.perform_now
    end
  end
end
