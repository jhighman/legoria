# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @organization = organizations(:acme)
    @admin = users(:admin)
    @recruiter = users(:recruiter)
    @open_job = jobs(:open_job)
  end

  # Authentication tests
  test "redirects to sign in when not authenticated" do
    get root_url
    assert_redirected_to new_user_session_path
  end

  # Index tests
  test "index displays dashboard for authenticated user" do
    sign_in @recruiter
    get root_url
    assert_response :success
    assert_select "h1", /Dashboard/
  end

  test "index shows welcome message with user name" do
    sign_in @recruiter
    get root_url
    assert_response :success
    assert_select "p", /Welcome back, #{@recruiter.first_name}/
  end

  test "index displays key metrics" do
    sign_in @recruiter
    get root_url
    assert_response :success
    assert_select ".card", /Open Jobs/
    assert_select ".card", /Active Candidates/
    assert_select ".card", /New This Week/
    assert_select ".card", /Pending Approval/
  end

  test "index displays pipeline summary" do
    sign_in @recruiter
    get root_url
    assert_response :success
    assert_select "h6", /Pipeline Summary/
  end

  test "index shows pending approvals for admin" do
    sign_in @admin
    # Create a job pending approval
    job = Job.create!(
      organization: @organization,
      title: "Test Job",
      employment_type: "full_time",
      location_type: "remote",
      status: "pending_approval",
      headcount: 1
    )

    get root_url
    assert_response :success
  end

  test "index shows SLA alerts when candidates are stuck" do
    sign_in @recruiter
    # Set up an application that's been stuck for a while
    app = applications(:active_application)
    app.update_column(:last_activity_at, 20.days.ago)

    get root_url
    assert_response :success
  end

  test "index shows quick links" do
    sign_in @recruiter
    get root_url
    assert_response :success
    assert_select "h6", /Quick Links/
    assert_select "a", /All Jobs/
    assert_select "a", /All Candidates/
  end

  test "admin sees manage users link" do
    sign_in @admin
    get root_url
    assert_response :success
    assert_select "a", /Manage Users/
  end

  test "admin sees view all activity link" do
    sign_in @admin
    get root_url
    assert_response :success
    assert_select "a", /View all activity/
  end
end
