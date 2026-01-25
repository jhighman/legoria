# frozen_string_literal: true

require "test_helper"

module Reports
  class DiversityControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @organization = organizations(:acme)
      @admin = users(:admin)
      @recruiter = users(:recruiter)
    end

    test "should get index as admin" do
      sign_in @admin

      get reports_diversity_index_url

      assert_response :success
      assert_select "h1", /Diversity Metrics/
    end

    test "should deny access to recruiter" do
      sign_in @recruiter

      get reports_diversity_index_url

      assert_redirected_to root_path
    end

    test "should get adverse impact" do
      sign_in @admin

      get adverse_impact_reports_diversity_index_url

      assert_response :success
      assert_select "h1", /Adverse Impact/
    end

    test "should export PDF" do
      sign_in @admin

      get pdf_reports_diversity_index_url

      assert_response :success
      assert_equal "application/pdf", response.media_type
    end

    test "should return JSON" do
      sign_in @admin

      get reports_diversity_index_url, as: :json

      assert_response :success
      assert_equal "application/json", response.media_type
    end
  end
end
