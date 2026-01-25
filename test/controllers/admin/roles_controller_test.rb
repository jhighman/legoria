# frozen_string_literal: true

require "test_helper"

class Admin::RolesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = users(:admin)
    @recruiter = users(:recruiter)
    @admin_role = roles(:admin)
    @recruiter_role = roles(:recruiter)
    sign_in @admin
  end

  test "admin can access roles index" do
    get admin_roles_path
    assert_response :success
  end

  test "non-admin cannot access roles index" do
    sign_out @admin
    sign_in @recruiter
    get admin_roles_path
    assert_redirected_to root_path
  end

  test "admin can view role details" do
    get admin_role_path(@recruiter_role)
    assert_response :success
  end

  test "admin can assign user to role" do
    # Remove recruiter from recruiter role first
    @recruiter.user_roles.find_by(role: @recruiter_role)&.destroy

    assert_difference "@recruiter_role.users.count", 1 do
      post assign_user_admin_role_path(@recruiter_role), params: { user_id: @recruiter.id }
    end
    assert_redirected_to admin_role_path(@recruiter_role)
  end

  test "admin can remove user from role" do
    # Make sure recruiter has the role
    @recruiter.roles << @recruiter_role unless @recruiter.roles.include?(@recruiter_role)

    assert_difference "@recruiter_role.users.count", -1 do
      delete remove_user_admin_role_path(@recruiter_role), params: { user_id: @recruiter.id }
    end
    assert_redirected_to admin_role_path(@recruiter_role)
  end

  test "admin cannot remove own admin role" do
    # Ensure admin has admin role
    @admin.roles << @admin_role unless @admin.roles.include?(@admin_role)

    assert_no_difference "@admin_role.users.count" do
      delete remove_user_admin_role_path(@admin_role), params: { user_id: @admin.id }
    end
    assert_redirected_to admin_role_path(@admin_role)
    assert_includes flash[:alert], "cannot remove your own admin role"
  end
end
