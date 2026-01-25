# frozen_string_literal: true

require "test_helper"

class Admin::I9VerificationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @recruiter = users(:recruiter)
    @verification = i9_verifications(:pending_section1)
    sign_in @admin
  end

  test "admin can access index" do
    get admin_i9_verifications_path
    assert_response :success
  end

  test "recruiter can access index" do
    sign_out @admin
    sign_in @recruiter
    get admin_i9_verifications_path
    assert_response :success
  end

  test "unauthenticated user cannot access index" do
    sign_out @admin
    get admin_i9_verifications_path
    assert_redirected_to new_user_session_path
  end

  test "admin can view pending verifications" do
    get pending_admin_i9_verifications_path
    assert_response :success
  end

  test "admin can view overdue verifications" do
    get overdue_admin_i9_verifications_path
    assert_response :success
  end

  test "admin can view verification details" do
    get admin_i9_verification_path(@verification)
    assert_response :success
  end

  test "admin can access new verification form" do
    get new_admin_i9_verification_path
    assert_response :success
  end

  test "admin can access section2 for section1_complete verification" do
    @verification.update_columns(status: "section1_complete")
    get section2_admin_i9_verification_path(@verification)
    assert_response :success
  end

  test "admin cannot access section2 for pending_section1 verification" do
    @verification.update_columns(status: "pending_section1")
    get section2_admin_i9_verification_path(@verification)
    # Pundit denies access because section2? policy requires section1_complete status
    assert_redirected_to root_path
  end

  test "admin can access section3 for verified verification" do
    @verification.update_columns(status: "verified")
    get section3_admin_i9_verification_path(@verification)
    assert_response :success
  end

  test "admin cannot access section3 for non-verified verification" do
    @verification.update_columns(status: "section1_complete")
    get section3_admin_i9_verification_path(@verification)
    # Pundit denies access because section3? policy requires verified status
    assert_redirected_to root_path
  end

  test "filters by status" do
    get admin_i9_verifications_path, params: { status: "pending_section1" }
    assert_response :success
  end

  test "filters by deadline" do
    get admin_i9_verifications_path, params: { deadline: "today" }
    assert_response :success
  end

  test "searches by candidate name" do
    get admin_i9_verifications_path, params: { search: "John" }
    assert_response :success
  end
end
