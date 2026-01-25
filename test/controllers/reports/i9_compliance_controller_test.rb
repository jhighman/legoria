# frozen_string_literal: true

require "test_helper"

module Reports
  class I9ComplianceControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @organization = organizations(:acme)
      @admin = users(:admin)
      @recruiter = users(:recruiter)
    end

    test "should get index" do
      sign_in @admin

      get reports_i9_compliance_index_url

      assert_response :success
      assert_select "h1", /I-9 Compliance/
    end

    test "should get index as recruiter" do
      sign_in @recruiter

      get reports_i9_compliance_index_url

      assert_response :success
    end

    test "should filter by date range" do
      sign_in @admin

      get reports_i9_compliance_index_url, params: { range: "last_30_days" }

      assert_response :success
    end

    test "should filter by status" do
      sign_in @admin

      get reports_i9_compliance_index_url, params: { status: "verified" }

      assert_response :success
    end

    test "should export CSV" do
      sign_in @admin

      get export_reports_i9_compliance_index_url

      assert_response :success
      assert_equal "text/csv; charset=utf-8", response.content_type
    end

    test "should export PDF" do
      sign_in @admin

      get pdf_reports_i9_compliance_index_url

      assert_response :success
      assert_equal "application/pdf", response.media_type
    end

    test "should return JSON" do
      sign_in @admin

      get reports_i9_compliance_index_url, as: :json

      assert_response :success
      assert_equal "application/json", response.media_type
    end

    test "requires authentication" do
      get reports_i9_compliance_index_url

      assert_redirected_to new_user_session_path
    end
  end
end
