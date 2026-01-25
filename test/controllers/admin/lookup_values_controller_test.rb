# frozen_string_literal: true

require "test_helper"

class Admin::LookupValuesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = users(:admin)
    @lookup_type = lookup_types(:acme_employment_type)
    @lookup_value = lookup_values(:acme_full_time)
    sign_in @admin
  end

  test "admin can access new lookup value form" do
    get new_admin_lookup_type_lookup_value_path(@lookup_type)
    assert_response :success
  end

  test "admin can create lookup value" do
    assert_difference "@lookup_type.lookup_values.count", 1 do
      post admin_lookup_type_lookup_values_path(@lookup_type), params: {
        lookup_value: {
          code: "freelance",
          translations_en_name: "Freelance",
          translations_en_description: "Freelance work"
        }
      }
    end
    assert_redirected_to admin_lookup_type_path(@lookup_type)
  end

  test "admin can access edit lookup value form" do
    get edit_admin_lookup_type_lookup_value_path(@lookup_type, @lookup_value)
    assert_response :success
  end

  test "admin can update lookup value" do
    patch admin_lookup_type_lookup_value_path(@lookup_type, @lookup_value), params: {
      lookup_value: {
        translations_en_name: "Full-Time Employment"
      }
    }
    assert_redirected_to admin_lookup_type_path(@lookup_type)
    @lookup_value.reload
    assert_equal "Full-Time Employment", @lookup_value.translations["en"]["name"]
  end

  test "admin can delete lookup value" do
    assert_difference "@lookup_type.lookup_values.count", -1 do
      delete admin_lookup_type_lookup_value_path(@lookup_type, @lookup_value)
    end
    assert_redirected_to admin_lookup_type_path(@lookup_type)
  end

  test "admin can toggle lookup value active status" do
    patch toggle_active_admin_lookup_type_lookup_value_path(@lookup_type, @lookup_value)
    assert_redirected_to admin_lookup_type_path(@lookup_type)
    @lookup_value.reload
    assert_not @lookup_value.active?
  end

  test "admin can move lookup value up" do
    second_value = lookup_values(:acme_part_time)
    original_position = second_value.position

    patch move_admin_lookup_type_lookup_value_path(@lookup_type, second_value), params: { direction: "up" }

    assert_redirected_to admin_lookup_type_path(@lookup_type)
    second_value.reload
    assert second_value.position < original_position
  end

  test "admin can move lookup value down" do
    original_position = @lookup_value.position

    patch move_admin_lookup_type_lookup_value_path(@lookup_type, @lookup_value), params: { direction: "down" }

    assert_redirected_to admin_lookup_type_path(@lookup_type)
    @lookup_value.reload
    assert @lookup_value.position > original_position
  end
end
