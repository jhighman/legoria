# frozen_string_literal: true

require "test_helper"

class Admin::LookupTypesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = users(:admin)
    @recruiter = users(:recruiter)
    @lookup_type = lookup_types(:acme_employment_type)
    sign_in @admin
  end

  test "admin can access lookup types index" do
    get admin_lookup_types_path
    assert_response :success
  end

  test "non-admin cannot access lookup types index" do
    sign_out @admin
    sign_in @recruiter
    get admin_lookup_types_path
    assert_redirected_to root_path
  end

  test "admin can view lookup type details" do
    get admin_lookup_type_path(@lookup_type)
    assert_response :success
  end

  test "admin can access edit lookup type form" do
    get edit_admin_lookup_type_path(@lookup_type)
    assert_response :success
  end

  test "admin can update lookup type" do
    patch admin_lookup_type_path(@lookup_type), params: {
      lookup_type: {
        name: "Updated Name",
        description: "Updated description"
      }
    }
    assert_redirected_to admin_lookup_type_path(@lookup_type)
    @lookup_type.reload
    assert_equal "Updated Name", @lookup_type.name
  end

  test "admin can deactivate lookup type" do
    patch admin_lookup_type_path(@lookup_type), params: {
      lookup_type: { active: false }
    }
    assert_redirected_to admin_lookup_type_path(@lookup_type)
    @lookup_type.reload
    assert_not @lookup_type.active?
  end
end
