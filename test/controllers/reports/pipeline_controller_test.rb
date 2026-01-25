# frozen_string_literal: true

require "test_helper"

module Reports
  class PipelineControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @organization = organizations(:acme)
      @admin = users(:admin)
    end

    test "should get index" do
      sign_in @admin

      get reports_pipeline_index_url

      assert_response :success
      assert_select "h1", /Pipeline Conversion/
    end

    test "should export CSV" do
      sign_in @admin

      get export_reports_pipeline_index_url

      assert_response :success
      assert_equal "text/csv; charset=utf-8", response.content_type
    end
  end
end
