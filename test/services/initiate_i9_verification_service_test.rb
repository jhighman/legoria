# frozen_string_literal: true

require "test_helper"

class InitiateI9VerificationServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization

    # Create a new application in offered status without existing I-9
    @job = jobs(:open_job)
    @candidate = candidates(:john_doe)

    # Use a different candidate to avoid unique constraint
    @new_candidate = Candidate.create!(
      organization: @organization,
      first_name: "Test",
      last_name: "Candidate",
      email: "test.candidate@example.com"
    )

    @application = Application.create!(
      organization: @organization,
      job: @job,
      candidate: @new_candidate,
      current_stage: stages(:screening),
      status: "offered",
      source_type: "career_site",
      applied_at: 5.days.ago
    )
  end

  teardown do
    Current.reset
  end

  test "creates I9 verification for valid application" do
    result = InitiateI9VerificationService.call(
      application: @application,
      expected_start_date: 14.days.from_now.to_date
    )

    assert result.success?
    verification = result.value!
    assert_equal @application, verification.application
    assert_equal @new_candidate, verification.candidate
    assert_equal "pending_section1", verification.status
    assert_equal 14.days.from_now.to_date, verification.employee_start_date
  end

  test "sets deadlines correctly" do
    start_date = 14.days.from_now.to_date
    result = InitiateI9VerificationService.call(
      application: @application,
      expected_start_date: start_date
    )

    verification = result.value!
    assert_equal start_date, verification.deadline_section1
    assert_not_nil verification.deadline_section2
  end

  test "updates application i9_status" do
    InitiateI9VerificationService.call(
      application: @application,
      expected_start_date: 14.days.from_now.to_date
    )

    @application.reload
    assert_equal "pending_section1", @application.i9_status
    assert_equal 14.days.from_now.to_date, @application.expected_start_date
  end

  test "fails for non-offered application" do
    @application.update_column(:status, "screening")

    result = InitiateI9VerificationService.call(
      application: @application,
      expected_start_date: 14.days.from_now.to_date
    )

    assert result.failure?
    assert_equal :application_not_offered, result.failure
  end

  test "fails if I9 verification already exists" do
    # Create existing verification
    I9Verification.create!(
      organization: @organization,
      application: @application,
      candidate: @new_candidate,
      status: "pending_section1",
      employee_start_date: 14.days.from_now.to_date
    )

    result = InitiateI9VerificationService.call(
      application: @application,
      expected_start_date: 14.days.from_now.to_date
    )

    assert result.failure?
    assert_equal :i9_verification_exists, result.failure
  end

  test "queues notification job" do
    assert_enqueued_with(job: I9NotificationJob) do
      InitiateI9VerificationService.call(
        application: @application,
        expected_start_date: 14.days.from_now.to_date
      )
    end
  end
end
