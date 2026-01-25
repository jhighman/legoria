# frozen_string_literal: true

require "test_helper"

class RescheduleInterviewServiceTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @interview = interviews(:scheduled_interview)
    @user = users(:recruiter)
  end

  def teardown
    Current.organization = nil
  end

  test "reschedules interview successfully" do
    new_time = 5.days.from_now
    original_time = @interview.scheduled_at

    result = RescheduleInterviewService.call(
      interview: @interview,
      scheduled_at: new_time,
      rescheduled_by: @user,
      reason: "Interviewer availability changed",
      send_notifications: false
    )

    assert result.success?
    @interview.reload
    assert_in_delta new_time.to_i, @interview.scheduled_at.to_i, 1
  end

  test "updates duration when provided" do
    result = RescheduleInterviewService.call(
      interview: @interview,
      scheduled_at: 5.days.from_now,
      rescheduled_by: @user,
      duration_minutes: 90,
      send_notifications: false
    )

    assert result.success?
    @interview.reload
    assert_equal 90, @interview.duration_minutes
  end

  test "updates location when provided" do
    result = RescheduleInterviewService.call(
      interview: @interview,
      scheduled_at: 5.days.from_now,
      rescheduled_by: @user,
      location: "New Conference Room",
      send_notifications: false
    )

    assert result.success?
    @interview.reload
    assert_equal "New Conference Room", @interview.location
  end

  test "fails if interview is nil" do
    result = RescheduleInterviewService.call(
      interview: nil,
      scheduled_at: 5.days.from_now,
      rescheduled_by: @user,
      send_notifications: false
    )

    assert result.failure?
    assert_equal :interview_not_found, result.failure
  end

  test "fails if interview is not active" do
    completed = interviews(:completed_interview)

    result = RescheduleInterviewService.call(
      interview: completed,
      scheduled_at: 5.days.from_now,
      rescheduled_by: @user,
      send_notifications: false
    )

    assert result.failure?
    assert_equal :interview_not_active, result.failure
  end

  test "fails if new time is not in future" do
    result = RescheduleInterviewService.call(
      interview: @interview,
      scheduled_at: 1.day.ago,
      rescheduled_by: @user,
      send_notifications: false
    )

    assert result.failure?
    assert_equal :must_be_in_future, result.failure
  end

  test "fails if scheduled_at is blank" do
    result = RescheduleInterviewService.call(
      interview: @interview,
      scheduled_at: nil,
      rescheduled_by: @user,
      send_notifications: false
    )

    assert result.failure?
    assert_equal :scheduled_at_required, result.failure
  end

  test "fails if new time is same as current" do
    result = RescheduleInterviewService.call(
      interview: @interview,
      scheduled_at: @interview.scheduled_at,
      rescheduled_by: @user,
      send_notifications: false
    )

    assert result.failure?
    assert_equal :same_time, result.failure
  end
end
