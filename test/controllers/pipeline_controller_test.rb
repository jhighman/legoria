# frozen_string_literal: true

require "test_helper"

class PipelineControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @organization = organizations(:acme)
    @recruiter = users(:recruiter)
    @admin = users(:admin)
    @hiring_manager = users(:hiring_manager)
    @open_job = jobs(:open_job)
    @active_application = applications(:active_application)
    @new_application = applications(:new_application)
    @applied_stage = stages(:applied)
    @screening_stage = stages(:screening)
    @interview_stage = stages(:interview)
    @rejected_stage = stages(:rejected)
    @rejection_reason = rejection_reasons(:not_qualified)
  end

  # Authentication tests
  test "show redirects to sign in when not authenticated" do
    get job_pipeline_url(@open_job)
    assert_redirected_to new_user_session_path
  end

  # Show (Kanban) tests
  test "show displays kanban view for recruiter" do
    sign_in @recruiter
    get job_pipeline_url(@open_job)
    assert_response :success
    assert_select "h1", /Pipeline/
    assert_select "#pipeline-board"
  end

  test "show displays applications grouped by stage" do
    sign_in @recruiter
    get job_pipeline_url(@open_job)
    assert_response :success
  end

  test "hiring manager can view pipeline for their job" do
    sign_in @hiring_manager
    @open_job.update!(hiring_manager: @hiring_manager)
    get job_pipeline_url(@open_job)
    assert_response :success
  end

  test "show filters by source" do
    sign_in @recruiter
    get job_pipeline_url(@open_job, source: "referral")
    assert_response :success
  end

  test "show filters by rating" do
    sign_in @recruiter
    get job_pipeline_url(@open_job, rating: 4)
    assert_response :success
  end

  test "show filters by starred" do
    sign_in @recruiter
    get job_pipeline_url(@open_job, starred: "true")
    assert_response :success
  end

  test "show filters by date range" do
    sign_in @recruiter
    get job_pipeline_url(@open_job, applied_after: 10.days.ago.to_date, applied_before: Date.today)
    assert_response :success
  end

  # List view tests
  test "list displays table view for recruiter" do
    sign_in @recruiter
    get list_job_pipeline_url(@open_job)
    assert_response :success
    assert_select "table"
  end

  test "list applies filters" do
    sign_in @recruiter
    get list_job_pipeline_url(@open_job, starred: "true")
    assert_response :success
  end

  # Move stage tests
  test "move_stage moves application to new stage" do
    sign_in @recruiter
    @active_application.update!(current_stage: @applied_stage)

    post move_stage_job_pipeline_url(@open_job, id: @active_application.id, stage_id: @interview_stage.id)

    assert_redirected_to job_pipeline_url(@open_job)
    @active_application.reload
    assert_equal @interview_stage.id, @active_application.current_stage_id
  end

  test "move_stage responds to turbo stream" do
    sign_in @recruiter
    @active_application.update!(current_stage: @applied_stage)

    post move_stage_job_pipeline_url(@open_job, id: @active_application.id, stage_id: @interview_stage.id),
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  test "move_stage creates stage transition record" do
    sign_in @recruiter
    @active_application.update!(current_stage: @applied_stage)

    assert_difference("StageTransition.count") do
      post move_stage_job_pipeline_url(@open_job, id: @active_application.id, stage_id: @interview_stage.id)
    end
  end

  test "hiring manager can move stage for their job" do
    sign_in @hiring_manager
    @open_job.update!(hiring_manager: @hiring_manager)
    @active_application.update!(current_stage: @applied_stage)

    post move_stage_job_pipeline_url(@open_job, id: @active_application.id, stage_id: @interview_stage.id)

    assert_redirected_to job_pipeline_url(@open_job)
    @active_application.reload
    assert_equal @interview_stage.id, @active_application.current_stage_id
  end

  # Reject tests
  test "reject transitions application to rejected" do
    sign_in @recruiter
    @active_application.update!(current_stage: @screening_stage, status: "screening")

    post reject_application_job_pipeline_url(@open_job, id: @active_application.id,
                                             rejection_reason_id: @rejection_reason.id,
                                             notes: "Not a good fit")

    assert_redirected_to job_pipeline_url(@open_job)
    @active_application.reload
    assert_equal "rejected", @active_application.status
  end

  test "reject responds to turbo stream" do
    sign_in @recruiter
    @active_application.update!(current_stage: @screening_stage, status: "screening")

    post reject_application_job_pipeline_url(@open_job, id: @active_application.id,
                                             rejection_reason_id: @rejection_reason.id),
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  test "reject creates stage transition to rejected stage" do
    sign_in @recruiter
    @active_application.update!(current_stage: @screening_stage, status: "screening")

    assert_difference("StageTransition.count") do
      post reject_application_job_pipeline_url(@open_job, id: @active_application.id,
                                               rejection_reason_id: @rejection_reason.id)
    end
  end

  # Star tests
  test "star marks application as starred" do
    sign_in @recruiter
    @active_application.update!(starred: false)

    post star_application_job_pipeline_url(@open_job, id: @active_application.id)

    assert_redirected_to job_pipeline_url(@open_job)
    @active_application.reload
    assert @active_application.starred?
  end

  test "star responds to turbo stream" do
    sign_in @recruiter
    @active_application.update!(starred: false)

    post star_application_job_pipeline_url(@open_job, id: @active_application.id),
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # Unstar tests
  test "unstar removes star from application" do
    sign_in @recruiter
    @active_application.update!(starred: true)

    post unstar_application_job_pipeline_url(@open_job, id: @active_application.id)

    assert_redirected_to job_pipeline_url(@open_job)
    @active_application.reload
    assert_not @active_application.starred?
  end

  test "unstar responds to turbo stream" do
    sign_in @recruiter
    @active_application.update!(starred: true)

    post unstar_application_job_pipeline_url(@open_job, id: @active_application.id),
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # Rate tests
  test "rate sets application rating" do
    sign_in @recruiter
    @active_application.update!(rating: nil)

    post rate_application_job_pipeline_url(@open_job, id: @active_application.id, rating: 5)

    assert_redirected_to job_pipeline_url(@open_job)
    @active_application.reload
    assert_equal 5, @active_application.rating
  end

  test "rate updates rating to new value" do
    sign_in @recruiter
    @active_application.update!(rating: 4)

    post rate_application_job_pipeline_url(@open_job, id: @active_application.id, rating: 3)

    assert_redirected_to job_pipeline_url(@open_job)
    @active_application.reload
    assert_equal 3, @active_application.rating
  end

  test "rate responds to turbo stream" do
    sign_in @recruiter
    post rate_application_job_pipeline_url(@open_job, id: @active_application.id, rating: 3),
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # Authorization tests
  test "unauthorized user cannot access pipeline from other organization" do
    other_org = Organization.create!(name: "Other Org", subdomain: "other")
    other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      first_name: "Other",
      last_name: "User",
      organization: other_org
    )
    sign_in other_user

    # Job from different org is not found (404) since organization scoping prevents access
    get job_pipeline_url(@open_job)
    assert_response :not_found
  end
end
