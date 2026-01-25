# frozen_string_literal: true

require "test_helper"

module Reports
  class OperationalControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @organization = organizations(:acme)
      @admin = users(:admin)
      @recruiter = users(:recruiter)
      @hiring_manager = users(:hiring_manager)
    end

    test "should get index as admin" do
      sign_in @admin

      get reports_operational_index_url

      assert_response :success
      assert_select "h1", /Operational Dashboard/
    end

    test "should get index as recruiter" do
      sign_in @recruiter

      get reports_operational_index_url

      assert_response :success
    end

    test "should deny access to hiring manager" do
      sign_in @hiring_manager

      get reports_operational_index_url

      assert_redirected_to root_path
    end

    test "should get recruiter productivity" do
      sign_in @admin

      get recruiter_productivity_reports_operational_index_url

      assert_response :success
      assert_select "h1", /Recruiter Productivity/
    end

    test "should get requisition aging" do
      sign_in @admin

      get requisition_aging_reports_operational_index_url

      assert_response :success
      assert_select "h1", /Requisition Aging/
    end

    test "should export productivity CSV" do
      sign_in @admin

      get export_reports_operational_index_url, params: { type: "productivity" }

      assert_response :success
      assert_equal "text/csv; charset=utf-8", response.content_type
    end

    test "should export aging CSV" do
      sign_in @admin

      get export_reports_operational_index_url, params: { type: "aging" }

      assert_response :success
      assert_equal "text/csv; charset=utf-8", response.content_type
    end
  end
end
