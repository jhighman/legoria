# frozen_string_literal: true

require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = users(:admin)
    @recruiter = users(:recruiter)
    sign_in @admin
  end

  test "admin can access users index" do
    get admin_users_path
    assert_response :success
  end

  test "non-admin cannot access users index" do
    sign_out @admin
    sign_in @recruiter
    get admin_users_path
    assert_redirected_to root_path
  end

  test "admin can view user details" do
    get admin_user_path(@recruiter)
    assert_response :success
  end

  test "admin can access new user form" do
    get new_admin_user_path
    assert_response :success
  end

  test "admin can create new user" do
    assert_difference "User.count", 1 do
      post admin_users_path, params: {
        user: {
          first_name: "New",
          last_name: "User",
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_redirected_to admin_user_path(User.last)
  end

  test "admin can access edit user form" do
    get edit_admin_user_path(@recruiter)
    assert_response :success
  end

  test "admin can update user" do
    patch admin_user_path(@recruiter), params: {
      user: {
        first_name: "Updated"
      }
    }
    assert_redirected_to admin_user_path(@recruiter)
    @recruiter.reload
    assert_equal "Updated", @recruiter.first_name
  end

  test "admin can deactivate user" do
    patch deactivate_admin_user_path(@recruiter)
    assert_redirected_to admin_users_path
    @recruiter.reload
    assert_not @recruiter.active?
  end

  test "admin cannot deactivate themselves" do
    patch deactivate_admin_user_path(@admin)
    assert_redirected_to admin_users_path
    @admin.reload
    assert @admin.active?
  end

  test "admin can activate inactive user" do
    @recruiter.update!(active: false)
    patch activate_admin_user_path(@recruiter)
    assert_redirected_to admin_users_path
    @recruiter.reload
    assert @recruiter.active?
  end
end
