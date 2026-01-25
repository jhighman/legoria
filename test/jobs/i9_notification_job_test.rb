# frozen_string_literal: true

require "test_helper"

class I9NotificationJobTest < ActiveJob::TestCase
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
    @application = applications(:active_application)
  end

  teardown do
    Current.reset
  end

  test "performs successfully for section1_request" do
    assert_nothing_raised do
      I9NotificationJob.perform_now(@application.id, "section1_request")
    end
  end

  test "performs successfully for section1_complete" do
    assert_nothing_raised do
      I9NotificationJob.perform_now(@application.id, "section1_complete")
    end
  end

  test "performs successfully for section2_complete" do
    assert_nothing_raised do
      I9NotificationJob.perform_now(@application.id, "section2_complete")
    end
  end

  test "performs successfully for section2_reminder" do
    assert_nothing_raised do
      I9NotificationJob.perform_now(@application.id, "section2_reminder")
    end
  end

  test "handles invalid application gracefully" do
    assert_nothing_raised do
      I9NotificationJob.perform_now(999999, "section1_request")
    end
  end

  test "handles unknown notification type gracefully" do
    assert_nothing_raised do
      I9NotificationJob.perform_now(@application.id, "unknown_type")
    end
  end

  test "resets Current after completion" do
    Current.organization = @organization
    I9NotificationJob.perform_now(@application.id, "section1_request")
    assert_nil Current.organization
  end
end
