# frozen_string_literal: true

require "test_helper"

class CancelInterviewServiceTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @interview = interviews(:scheduled_interview)
    @user = users(:recruiter)
  end

  def teardown
    Current.organization = nil
  end

  test "cancels interview successfully" do
    result = CancelInterviewService.call(
      interview: @interview,
      cancelled_by: @user,
      reason: "Position filled",
      send_notifications: false
    )

    assert result.success?
    @interview.reload
    assert @interview.cancelled?
    assert_equal "Position filled", @interview.cancellation_reason
    assert_not_nil @interview.cancelled_at
  end

  test "fails if interview is nil" do
    result = CancelInterviewService.call(
      interview: nil,
      cancelled_by: @user,
      send_notifications: false
    )

    assert result.failure?
    assert_equal :interview_not_found, result.failure
  end

  test "fails if interview is already cancelled" do
    cancelled = interviews(:cancelled_interview)

    result = CancelInterviewService.call(
      interview: cancelled,
      cancelled_by: @user,
      send_notifications: false
    )

    assert result.failure?
    assert_equal :interview_already_cancelled, result.failure
  end

  test "fails if interview is already completed" do
    completed = interviews(:completed_interview)

    result = CancelInterviewService.call(
      interview: completed,
      cancelled_by: @user,
      send_notifications: false
    )

    assert result.failure?
    assert_equal :interview_already_completed, result.failure
  end

  test "can cancel confirmed interview" do
    confirmed = interviews(:confirmed_interview)

    result = CancelInterviewService.call(
      interview: confirmed,
      cancelled_by: @user,
      reason: "Candidate withdrew",
      send_notifications: false
    )

    assert result.success?
    confirmed.reload
    assert confirmed.cancelled?
  end

  test "reason is optional" do
    result = CancelInterviewService.call(
      interview: @interview,
      cancelled_by: @user,
      send_notifications: false
    )

    assert result.success?
    @interview.reload
    assert @interview.cancelled?
    assert_nil @interview.cancellation_reason
  end
end
