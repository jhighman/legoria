# frozen_string_literal: true

require "test_helper"

module Reports
  class WorkAuthorizationsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @organization = organizations(:acme)
      @admin = users(:admin)
      @recruiter = users(:recruiter)
    end

    test "should get index" do
      sign_in @admin

      get reports_work_authorizations_url

      assert_response :success
      assert_select "h1", /Work Authorizations/
    end

    test "should get index as recruiter" do
      sign_in @recruiter

      get reports_work_authorizations_url

      assert_response :success
    end

    test "should get expiring page" do
      sign_in @admin

      get expiring_reports_work_authorizations_url

      assert_response :success
    end

    test "should export CSV" do
      sign_in @admin

      get export_reports_work_authorizations_url

      assert_response :success
      assert_equal "text/csv; charset=utf-8", response.content_type
    end

    test "should return JSON" do
      sign_in @admin

      get reports_work_authorizations_url, as: :json

      assert_response :success
      assert_equal "application/json", response.media_type
    end

    test "requires authentication" do
      get reports_work_authorizations_url

      assert_redirected_to new_user_session_path
    end
  end
end
