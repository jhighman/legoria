# frozen_string_literal: true

require "test_helper"

class InterviewTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @interview = interviews(:scheduled_interview)
  end

  def teardown
    Current.organization = nil
  end

  test "valid interview" do
    assert @interview.valid?
  end

  test "requires interview_type" do
    @interview.interview_type = nil
    assert_not @interview.valid?
    assert_includes @interview.errors[:interview_type], "can't be blank"
  end

  test "requires valid interview_type" do
    @interview.interview_type = "invalid_type"
    assert_not @interview.valid?
    assert_includes @interview.errors[:interview_type], "is not included in the list"
  end

  test "requires title" do
    @interview.title = nil
    assert_not @interview.valid?
    assert_includes @interview.errors[:title], "can't be blank"
  end

  test "requires scheduled_at" do
    @interview.scheduled_at = nil
    assert_not @interview.valid?
    assert_includes @interview.errors[:scheduled_at], "can't be blank"
  end

  test "requires duration_minutes" do
    @interview.duration_minutes = nil
    assert_not @interview.valid?
    assert_includes @interview.errors[:duration_minutes], "can't be blank"
  end

  test "duration must be positive" do
    @interview.duration_minutes = 0
    assert_not @interview.valid?
    assert_includes @interview.errors[:duration_minutes], "must be greater than 0"
  end

  test "duration must be at most 480 minutes" do
    @interview.duration_minutes = 500
    assert_not @interview.valid?
    assert_includes @interview.errors[:duration_minutes], "must be less than or equal to 480"
  end

  # State machine tests
  test "initial state is scheduled" do
    interview = Interview.new
    assert_equal "scheduled", interview.status
  end

  test "can confirm scheduled interview" do
    assert @interview.scheduled?
    assert @interview.can_confirm?
    @interview.confirm
    assert @interview.confirmed?
    assert_not_nil @interview.confirmed_at
  end

  test "can complete scheduled interview" do
    assert @interview.can_complete?
    @interview.complete
    assert @interview.completed?
    assert_not_nil @interview.completed_at
  end

  test "can cancel scheduled interview" do
    assert @interview.can_cancel?
    @interview.cancel
    assert @interview.cancelled?
    assert_not_nil @interview.cancelled_at
  end

  test "can mark no_show" do
    assert @interview.can_mark_no_show?
    @interview.mark_no_show
    assert @interview.no_show?
  end

  test "cannot cancel completed interview" do
    completed = interviews(:completed_interview)
    assert_not completed.can_cancel?
  end

  # Status helpers
  test "active returns true for scheduled and confirmed" do
    assert @interview.active?
    confirmed = interviews(:confirmed_interview)
    assert confirmed.active?
  end

  test "terminal returns true for completed, cancelled, no_show" do
    completed = interviews(:completed_interview)
    assert completed.terminal?
    cancelled = interviews(:cancelled_interview)
    assert cancelled.terminal?
  end

  test "upcoming returns true for future active interviews" do
    assert @interview.upcoming?
  end

  test "past returns true for past interviews" do
    completed = interviews(:completed_interview)
    assert completed.past?
  end

  # Participant helpers
  test "lead_interviewer returns lead participant user" do
    lead_user = @interview.lead_interviewer
    assert_equal users(:hiring_manager), lead_user
  end

  test "add_participant creates new participant" do
    user = users(:admin)
    assert_difference -> { @interview.interview_participants.count }, 1 do
      @interview.add_participant(user, role: "interviewer")
    end
  end

  test "add_participant does not duplicate" do
    user = users(:hiring_manager) # already a lead
    assert_no_difference -> { @interview.interview_participants.count } do
      @interview.add_participant(user)
    end
  end

  test "remove_participant destroys participant" do
    user = users(:hiring_manager)
    assert_difference -> { @interview.interview_participants.count }, -1 do
      @interview.remove_participant(user)
    end
  end

  # Time helpers
  test "end_time calculates correctly" do
    expected = @interview.scheduled_at + 60.minutes
    assert_equal expected, @interview.end_time
  end

  test "duration_formatted for hours and minutes" do
    @interview.duration_minutes = 90
    assert_equal "1h 30m", @interview.duration_formatted
  end

  test "duration_formatted for just hours" do
    @interview.duration_minutes = 120
    assert_equal "2 hours", @interview.duration_formatted
  end

  test "duration_formatted for just minutes" do
    @interview.duration_minutes = 45
    assert_equal "45 minutes", @interview.duration_formatted
  end

  test "time_until returns nil for non-upcoming" do
    completed = interviews(:completed_interview)
    assert_nil completed.time_until
  end

  # Display helpers
  test "interview_type_label titleizes type" do
    assert_equal "Video", @interview.interview_type_label
    @interview.interview_type = "phone_screen"
    assert_equal "Phone Screen", @interview.interview_type_label
  end

  test "status_color returns appropriate color" do
    assert_equal "blue", @interview.status_color
    confirmed = interviews(:confirmed_interview)
    assert_equal "green", confirmed.status_color
  end

  # Scopes
  test "upcoming scope returns future active interviews" do
    upcoming = Interview.upcoming
    upcoming.each do |i|
      assert i.scheduled_at > Time.current
      assert i.active?
    end
  end

  test "past scope returns past interviews" do
    past = Interview.past
    past.each do |i|
      assert i.scheduled_at < Time.current
    end
  end

  test "for_user scope returns interviews for specific user" do
    user = users(:hiring_manager)
    interviews = Interview.for_user(user.id)
    interviews.each do |i|
      assert i.interview_participants.exists?(user_id: user.id)
    end
  end
end
