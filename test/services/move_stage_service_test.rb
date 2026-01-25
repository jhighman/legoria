# frozen_string_literal: true

require "test_helper"

class MoveStageServiceTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @application = applications(:active_application)
    @user = users(:recruiter)
    @screening_stage = stages(:screening)
    @interview_stage = stages(:interview)

    # Ensure job has job_stages set up
    @application.job.job_stages.find_or_create_by!(stage: @screening_stage) { |js| js.position = 0 }
    @application.job.job_stages.find_or_create_by!(stage: @interview_stage) { |js| js.position = 1 }
  end

  def teardown
    Current.organization = nil
  end

  test "successfully moves application to new stage" do
    result = MoveStageService.call(
      application: @application,
      to_stage: @interview_stage,
      moved_by: @user,
      notes: "Passed screening"
    )

    assert result.success?
    transition = result.value!

    assert_equal @screening_stage, transition.from_stage
    assert_equal @interview_stage, transition.to_stage
    assert_equal @user, transition.moved_by
    assert_equal "Passed screening", transition.notes

    @application.reload
    assert_equal @interview_stage, @application.current_stage
  end

  test "returns failure when application is nil" do
    result = MoveStageService.call(
      application: nil,
      to_stage: @interview_stage,
      moved_by: @user
    )

    assert result.failure?
    assert_equal :application_not_found, result.failure
  end

  test "returns failure when application is not active" do
    @application.reject!

    result = MoveStageService.call(
      application: @application,
      to_stage: @interview_stage,
      moved_by: @user
    )

    assert result.failure?
    assert_equal :application_not_active, result.failure
  end

  test "returns failure when application is discarded" do
    @application.discard!

    result = MoveStageService.call(
      application: @application,
      to_stage: @interview_stage,
      moved_by: @user
    )

    assert result.failure?
    assert_equal :application_discarded, result.failure
  end

  test "returns failure when stage is nil" do
    result = MoveStageService.call(
      application: @application,
      to_stage: nil,
      moved_by: @user
    )

    assert result.failure?
    assert_equal :stage_not_found, result.failure
  end

  test "returns failure when moving to same stage" do
    result = MoveStageService.call(
      application: @application,
      to_stage: @application.current_stage,
      moved_by: @user
    )

    assert result.failure?
    assert_equal :same_stage, result.failure
  end

  test "returns failure when stage not in job" do
    # Create a stage not associated with the job
    other_stage = Stage.create!(
      organization: @organization,
      name: "Other Stage",
      stage_type: "screening",
      position: 99
    )

    result = MoveStageService.call(
      application: @application,
      to_stage: other_stage,
      moved_by: @user
    )

    assert result.failure?
    assert_equal :stage_not_in_job, result.failure
  end

  test "creates stage transition record" do
    assert_difference("StageTransition.count") do
      MoveStageService.call(
        application: @application,
        to_stage: @interview_stage,
        moved_by: @user
      )
    end
  end

  test "updates application last_activity_at" do
    original_activity = @application.last_activity_at

    travel 1.hour do
      MoveStageService.call(
        application: @application,
        to_stage: @interview_stage,
        moved_by: @user
      )
    end

    @application.reload
    assert @application.last_activity_at > original_activity
  end
end
