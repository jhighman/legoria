# frozen_string_literal: true

require "test_helper"

module Reports
  class TimeToHireControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @organization = organizations(:acme)
      @admin = users(:admin)
      @recruiter = users(:recruiter)
      @job = jobs(:open_job)
    end

    test "should get index" do
      sign_in @admin

      get reports_time_to_hire_index_url

      assert_response :success
      assert_select "h1", /Time to Hire/
    end

    test "should get index as recruiter" do
      sign_in @recruiter

      get reports_time_to_hire_index_url

      assert_response :success
    end

    test "should filter by date range" do
      sign_in @admin

      get reports_time_to_hire_index_url, params: { range: "last_7_days" }

      assert_response :success
    end

    test "should filter by job" do
      sign_in @admin

      get reports_time_to_hire_index_url, params: { job_id: @job.id }

      assert_response :success
    end

    test "should export CSV" do
      sign_in @admin

      get export_reports_time_to_hire_index_url

      assert_response :success
      assert_equal "text/csv; charset=utf-8", response.content_type
    end

    test "should return JSON" do
      sign_in @admin

      get reports_time_to_hire_index_url, as: :json

      assert_response :success
      assert_equal "application/json", response.media_type
    end

    test "requires authentication" do
      get reports_time_to_hire_index_url

      assert_redirected_to new_user_session_path
    end
  end
end
