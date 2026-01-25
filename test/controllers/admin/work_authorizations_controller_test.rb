# frozen_string_literal: true

require "test_helper"

class Admin::WorkAuthorizationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @recruiter = users(:recruiter)
    @authorization = work_authorizations(:citizen)
    sign_in @admin
  end

  test "admin can access index" do
    get admin_work_authorizations_path
    assert_response :success
  end

  test "recruiter can access index" do
    sign_out @admin
    sign_in @recruiter
    get admin_work_authorizations_path
    assert_response :success
  end

  test "unauthenticated user cannot access index" do
    sign_out @admin
    get admin_work_authorizations_path
    assert_redirected_to new_user_session_path
  end

  test "admin can view expiring authorizations" do
    get expiring_admin_work_authorizations_path
    assert_response :success
  end

  test "admin can view authorization details" do
    get admin_work_authorization_path(@authorization)
    assert_response :success
  end

  test "filters by authorization type" do
    get admin_work_authorizations_path, params: { type: "citizen" }
    assert_response :success
  end

  test "filters by expiring timeframe" do
    get admin_work_authorizations_path, params: { expiring: "30" }
    assert_response :success
  end

  test "filters by indefinite status" do
    get admin_work_authorizations_path, params: { indefinite: "true" }
    assert_response :success
  end

  test "searches by candidate name" do
    get admin_work_authorizations_path, params: { search: "John" }
    assert_response :success
  end
end
