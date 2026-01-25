# frozen_string_literal: true

require "test_helper"

class JobsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @organization = organizations(:acme)
    @recruiter = users(:recruiter)
    @admin = users(:admin)
    @hiring_manager = users(:hiring_manager)
    @draft_job = jobs(:draft_job)
    @pending_job = jobs(:pending_job)
    @open_job = jobs(:open_job)
  end

  # Authentication tests
  test "redirects to sign in when not authenticated" do
    get jobs_url
    assert_redirected_to new_user_session_path
  end

  # Index tests
  test "index displays jobs for authenticated user" do
    sign_in @recruiter
    get jobs_url
    assert_response :success
    assert_select "h1", /Jobs/
  end

  test "index filters by status" do
    sign_in @recruiter
    get jobs_url(status: "draft")
    assert_response :success
  end

  test "index filters by department" do
    sign_in @recruiter
    dept = departments(:engineering)
    get jobs_url(department_id: dept.id)
    assert_response :success
  end

  # Show tests
  test "show displays job details" do
    sign_in @recruiter
    get job_url(@draft_job)
    assert_response :success
    assert_select "h1", @draft_job.title
  end

  test "hiring manager can view their assigned job" do
    sign_in @hiring_manager
    @draft_job.update!(hiring_manager: @hiring_manager)
    get job_url(@draft_job)
    assert_response :success
  end

  # New tests
  test "new displays form for recruiter" do
    sign_in @recruiter
    get new_job_url
    assert_response :success
    assert_select "form"
  end

  test "new from template populates form" do
    sign_in @recruiter
    template = job_templates(:engineer_template)
    get new_job_url(template_id: template.id)
    assert_response :success
  end

  # Create tests
  test "create creates job for recruiter" do
    sign_in @recruiter

    assert_difference("Job.count") do
      post jobs_url, params: {
        job: {
          title: "New Position",
          description: "Job description",
          employment_type: "full_time",
          location_type: "remote",
          headcount: 1
        }
      }
    end

    assert_redirected_to job_url(Job.last)
    follow_redirect!
    assert_select "div", /Job was successfully created/
  end

  test "create assigns recruiter automatically" do
    sign_in @recruiter

    post jobs_url, params: {
      job: {
        title: "New Position",
        employment_type: "full_time",
        location_type: "remote",
        headcount: 1
      }
    }

    assert_equal @recruiter.id, Job.last.recruiter_id
  end

  test "create with invalid params renders new" do
    sign_in @recruiter

    assert_no_difference("Job.count") do
      post jobs_url, params: {
        job: { title: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  # Edit tests
  test "edit displays form for recruiter" do
    sign_in @recruiter
    @draft_job.update!(recruiter: @recruiter)
    get edit_job_url(@draft_job)
    assert_response :success
    assert_select "form"
  end

  test "admin can edit any job" do
    sign_in @admin
    get edit_job_url(@draft_job)
    assert_response :success
  end

  # Update tests
  test "update modifies job" do
    sign_in @admin

    patch job_url(@draft_job), params: {
      job: { title: "Updated Title" }
    }

    assert_redirected_to job_url(@draft_job)
    @draft_job.reload
    assert_equal "Updated Title", @draft_job.title
  end

  test "update with invalid params renders edit" do
    sign_in @admin

    patch job_url(@draft_job), params: {
      job: { title: "" }
    }

    assert_response :unprocessable_entity
  end

  # Destroy tests
  test "admin can archive job" do
    sign_in @admin

    delete job_url(@draft_job)

    assert_redirected_to jobs_url
    @draft_job.reload
    assert @draft_job.discarded?
  end

  test "recruiter cannot archive job" do
    sign_in @recruiter

    delete job_url(@draft_job)

    assert_redirected_to root_path
    follow_redirect!
    assert_select "div", /You are not authorized/
  end

  # Workflow: submit_for_approval
  test "submit_for_approval transitions draft to pending" do
    sign_in @recruiter
    @draft_job.update!(recruiter: @recruiter, hiring_manager: @hiring_manager)

    post submit_for_approval_job_url(@draft_job)

    assert_redirected_to job_url(@draft_job)
    @draft_job.reload
    assert @draft_job.pending_approval?
  end

  test "submit_for_approval creates approval request" do
    sign_in @recruiter
    @draft_job.update!(recruiter: @recruiter, hiring_manager: @hiring_manager)

    assert_difference("JobApproval.count") do
      post submit_for_approval_job_url(@draft_job)
    end
  end

  test "cannot submit non-draft for approval" do
    sign_in @recruiter
    @pending_job.update!(recruiter: @recruiter)

    post submit_for_approval_job_url(@pending_job)

    # Policy denies non-draft submissions, so we get authorization error
    assert_redirected_to root_path
    follow_redirect!
    assert_select "div", /You are not authorized/
  end

  # Workflow: approve
  test "hiring manager can approve job they manage" do
    sign_in @hiring_manager
    @pending_job.update!(hiring_manager: @hiring_manager)
    @pending_job.job_approvals.create!(approver: @hiring_manager, status: "pending", sequence: 0)

    post approve_job_url(@pending_job)

    assert_redirected_to job_url(@pending_job)
    @pending_job.reload
    assert @pending_job.open?
  end

  test "admin can approve any job" do
    sign_in @admin
    @pending_job.job_approvals.create!(approver: @admin, status: "pending", sequence: 0)

    post approve_job_url(@pending_job)

    assert_redirected_to job_url(@pending_job)
    @pending_job.reload
    assert @pending_job.open?
  end

  # Workflow: reject
  test "hiring manager can reject job they manage" do
    sign_in @hiring_manager
    @pending_job.update!(hiring_manager: @hiring_manager)
    @pending_job.job_approvals.create!(approver: @hiring_manager, status: "pending", sequence: 0)

    post reject_job_url(@pending_job, params: { notes: "Needs changes" })

    assert_redirected_to job_url(@pending_job)
    @pending_job.reload
    assert @pending_job.draft?
  end

  # Workflow: put_on_hold
  test "put_on_hold transitions open job" do
    sign_in @recruiter
    @open_job.update!(recruiter: @recruiter)

    post put_on_hold_job_url(@open_job)

    assert_redirected_to job_url(@open_job)
    @open_job.reload
    assert @open_job.on_hold?
  end

  # Workflow: close
  test "close transitions open job" do
    sign_in @recruiter
    @open_job.update!(recruiter: @recruiter)

    post close_job_url(@open_job, params: { close_reason: "filled" })

    assert_redirected_to job_url(@open_job)
    @open_job.reload
    assert @open_job.closed?
  end

  # Workflow: reopen
  test "reopen transitions closed job" do
    sign_in @admin
    closed_job = jobs(:closed_job)

    post reopen_job_url(closed_job)

    assert_redirected_to job_url(closed_job)
    closed_job.reload
    assert closed_job.open?
  end

  # Workflow: duplicate
  test "duplicate creates copy of job" do
    sign_in @recruiter

    assert_difference("Job.count") do
      post duplicate_job_url(@open_job)
    end

    new_job = Job.last
    assert_redirected_to edit_job_url(new_job)
    assert_equal "Copy of #{@open_job.title}", new_job.title
    assert_equal "draft", new_job.status
  end

  # Pending approval listing
  test "pending_approval shows pending jobs for admin" do
    sign_in @admin
    get pending_approval_jobs_url
    assert_response :success
  end
end
