# frozen_string_literal: true

require "test_helper"

class InterviewSelfScheduleTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @self_schedule = interview_self_schedules(:pending_schedule)
  end

  def teardown
    Current.organization = nil
  end

  test "valid self schedule" do
    assert @self_schedule.valid?
  end

  test "requires scheduling_starts_at" do
    @self_schedule.scheduling_starts_at = nil
    assert_not @self_schedule.valid?
    assert_includes @self_schedule.errors[:scheduling_starts_at], "can't be blank"
  end

  test "requires scheduling_ends_at" do
    @self_schedule.scheduling_ends_at = nil
    assert_not @self_schedule.valid?
    assert_includes @self_schedule.errors[:scheduling_ends_at], "can't be blank"
  end

  test "validates scheduling window" do
    @self_schedule.scheduling_ends_at = @self_schedule.scheduling_starts_at - 1.day
    assert_not @self_schedule.valid?
    assert_includes @self_schedule.errors[:scheduling_ends_at], "must be after scheduling starts at"
  end

  test "validates status inclusion" do
    @self_schedule.status = "invalid"
    assert_not @self_schedule.valid?
    assert_includes @self_schedule.errors[:status], "is not included in the list"
  end

  test "generates token automatically" do
    new_schedule = InterviewSelfSchedule.new(
      interview: interviews(:completed_interview),
      scheduling_starts_at: Time.current,
      scheduling_ends_at: 7.days.from_now
    )
    new_schedule.valid?
    assert new_schedule.token.present?
  end

  # Status helpers
  test "pending? returns true for pending schedules" do
    assert @self_schedule.pending?
  end

  test "scheduled? returns true for scheduled schedules" do
    assert interview_self_schedules(:scheduled_self_schedule).scheduled?
  end

  test "expired? returns true for expired schedules" do
    assert interview_self_schedules(:expired_schedule).expired?
  end

  # Scheduling window
  test "scheduling_window_open? returns true when in window" do
    @self_schedule.scheduling_starts_at = 1.hour.ago
    @self_schedule.scheduling_ends_at = 1.day.from_now
    assert @self_schedule.scheduling_window_open?
  end

  test "scheduling_window_open? returns false when past window" do
    @self_schedule.scheduling_starts_at = 2.days.ago
    @self_schedule.scheduling_ends_at = 1.day.ago
    assert_not @self_schedule.scheduling_window_open?
  end

  test "can_schedule? returns true when pending and window open" do
    @self_schedule.status = "pending"
    @self_schedule.scheduling_starts_at = 1.hour.ago
    @self_schedule.scheduling_ends_at = 1.day.from_now
    assert @self_schedule.can_schedule?
  end

  # Slot management
  test "add_slot adds a new slot" do
    @self_schedule.available_slots = []
    start_time = 1.day.from_now
    @self_schedule.add_slot(start_time)
    assert_equal 1, @self_schedule.available_slots.length
  end

  test "available_slots_list returns only available slots" do
    available = @self_schedule.available_slots_list
    available.each { |slot| assert slot[:available] }
  end

  # Cancellation
  test "cancel! sets status to cancelled" do
    @self_schedule.cancel!
    assert @self_schedule.cancelled?
  end

  # Display helpers
  test "status_label returns formatted status" do
    assert_equal "Pending", @self_schedule.status_label
  end

  test "status_color returns appropriate color" do
    assert_equal "yellow", @self_schedule.status_color
    @self_schedule.status = "scheduled"
    assert_equal "green", @self_schedule.status_color
  end

  # Scopes
  test "pending scope returns only pending schedules" do
    pending = InterviewSelfSchedule.pending
    pending.each { |s| assert s.pending? }
  end

  test "active scope returns pending and scheduled" do
    active = InterviewSelfSchedule.active
    active.each { |s| assert s.pending? || s.scheduled? }
  end
end
