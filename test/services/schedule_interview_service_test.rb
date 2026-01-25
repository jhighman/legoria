# frozen_string_literal: true

require "test_helper"

class ScheduleInterviewServiceTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @application = applications(:active_application)
    @scheduler = users(:recruiter)
    @interviewer = users(:hiring_manager)
  end

  def teardown
    Current.organization = nil
  end

  test "schedules interview successfully" do
    result = ScheduleInterviewService.call(
      application: @application,
      interview_type: "video",
      scheduled_at: 3.days.from_now,
      scheduled_by: @scheduler,
      title: "Technical Interview",
      send_notifications: false
    )

    assert result.success?
    interview = result.value!
    assert_equal "video", interview.interview_type
    assert_equal "Technical Interview", interview.title
    assert_equal @scheduler, interview.scheduled_by
    assert_equal "scheduled", interview.status
  end

  test "adds participants successfully" do
    result = ScheduleInterviewService.call(
      application: @application,
      interview_type: "panel",
      scheduled_at: 3.days.from_now,
      scheduled_by: @scheduler,
      participants: [
        { user: @interviewer, role: "lead" }
      ],
      send_notifications: false
    )

    assert result.success?
    interview = result.value!
    assert_equal 1, interview.interview_participants.count
    assert_equal @interviewer, interview.lead_interviewer
  end

  test "adds scheduler as lead if no lead assigned" do
    result = ScheduleInterviewService.call(
      application: @application,
      interview_type: "phone_screen",
      scheduled_at: 3.days.from_now,
      scheduled_by: @scheduler,
      participants: [],
      send_notifications: false
    )

    assert result.success?
    interview = result.value!
    assert_equal @scheduler, interview.lead_interviewer
  end

  test "uses default duration for interview type" do
    result = ScheduleInterviewService.call(
      application: @application,
      interview_type: "phone_screen",
      scheduled_at: 3.days.from_now,
      scheduled_by: @scheduler,
      send_notifications: false
    )

    assert result.success?
    interview = result.value!
    assert_equal 30, interview.duration_minutes # phone_screen default
  end

  test "fails if application is nil" do
    result = ScheduleInterviewService.call(
      application: nil,
      interview_type: "video",
      scheduled_at: 3.days.from_now,
      scheduled_by: @scheduler,
      send_notifications: false
    )

    assert result.failure?
    assert_equal :application_not_found, result.failure
  end

  test "fails if application is not active" do
    rejected_app = applications(:rejected_application)
    result = ScheduleInterviewService.call(
      application: rejected_app,
      interview_type: "video",
      scheduled_at: 3.days.from_now,
      scheduled_by: @scheduler,
      send_notifications: false
    )

    assert result.failure?
    assert_equal :application_not_active, result.failure
  end

  test "fails if participant is from wrong organization" do
    other_org = Organization.create!(name: "Other Org", subdomain: "other")
    other_user = User.create!(
      organization: other_org,
      email: "other@example.com",
      first_name: "Other",
      last_name: "User",
      password: "password123",
      password_confirmation: "password123"
    )

    result = ScheduleInterviewService.call(
      application: @application,
      interview_type: "video",
      scheduled_at: 3.days.from_now,
      scheduled_by: @scheduler,
      participants: [{ user: other_user, role: "interviewer" }],
      send_notifications: false
    )

    assert result.failure?
    assert_equal :participant_wrong_organization, result.failure
  end

  test "sets location and video url when provided" do
    result = ScheduleInterviewService.call(
      application: @application,
      interview_type: "video",
      scheduled_at: 3.days.from_now,
      scheduled_by: @scheduler,
      location: "Conference Room A",
      video_meeting_url: "https://zoom.us/j/123",
      send_notifications: false
    )

    assert result.success?
    interview = result.value!
    assert_equal "Conference Room A", interview.location
    assert_equal "https://zoom.us/j/123", interview.video_meeting_url
  end
end
