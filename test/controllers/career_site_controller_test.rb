# frozen_string_literal: true

require "test_helper"

class CareerSiteControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = organizations(:acme)
    @open_job = jobs(:open_job)
    @draft_job = jobs(:draft_job)
  end

  # Index tests
  test "index displays public career site without authentication" do
    get careers_url
    assert_response :success
  end

  test "index shows only open jobs" do
    get careers_url
    assert_response :success
    assert_select "h5.card-title", @open_job.title
  end

  test "index does not show draft jobs" do
    get careers_url
    assert_response :success
    assert_no_match @draft_job.title, response.body
  end

  test "index filters by department" do
    department = @open_job.department
    get careers_url, params: { department: department.id }
    assert_response :success
  end

  test "index filters by location type" do
    get careers_url, params: { location_type: "remote" }
    assert_response :success
  end

  test "index filters by employment type" do
    get careers_url, params: { employment_type: "full_time" }
    assert_response :success
  end

  test "index searches by job title" do
    get careers_url, params: { q: @open_job.title.split.first }
    assert_response :success
    assert_select "h5.card-title", @open_job.title
  end

  test "index shows no results message when no jobs match" do
    get careers_url, params: { q: "NonexistentJobTitle12345" }
    assert_response :success
    assert_select "h4", /No open positions found/
  end

  # Show tests
  test "show displays job details" do
    get career_url(@open_job)
    assert_response :success
    assert_select "h1", @open_job.title
  end

  test "show displays job description" do
    @open_job.update!(description: "This is a great job opportunity.")
    get career_url(@open_job)
    assert_response :success
    assert_match "great job opportunity", response.body
  end

  test "show displays apply button" do
    get career_url(@open_job)
    assert_response :success
    assert_select "a[href=?]", apply_career_path(@open_job)
  end

  test "show displays hiring process stages" do
    get career_url(@open_job)
    assert_response :success
    assert_select ".hiring-steps"
  end

  test "show returns 404 for draft job" do
    get "/careers/#{@draft_job.id}"
    assert_response :not_found
  end

  test "show returns 404 for closed job" do
    closed_job = Job.create!(
      organization: @organization,
      title: "Closed Position",
      employment_type: "full_time",
      location_type: "remote",
      status: "closed",
      headcount: 1
    )

    get "/careers/#{closed_job.id}"
    assert_response :not_found
  end
end
