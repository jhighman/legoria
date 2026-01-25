# frozen_string_literal: true

require "test_helper"

class LookupServiceTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
  end

  test "values_for_select returns array of name-code pairs" do
    values = LookupService.values_for_select("employment_type", organization: @organization)

    assert_kind_of Array, values
    assert values.any?
    assert values.all? { |v| v.is_a?(Array) && v.length == 2 }

    # Check that it includes full_time
    codes = values.map(&:last)
    assert_includes codes, "full_time"
  end

  test "values_for_select returns empty array when organization nil" do
    values = LookupService.values_for_select("employment_type", organization: nil)
    assert_equal [], values
  end

  test "values_for_select returns empty array for unknown type" do
    values = LookupService.values_for_select("unknown_type", organization: @organization)
    assert_equal [], values
  end

  test "find_value returns lookup value by code" do
    value = LookupService.find_value("employment_type", "full_time", organization: @organization)

    assert_not_nil value
    assert_equal "full_time", value.code
  end

  test "find_value returns nil for unknown code" do
    value = LookupService.find_value("employment_type", "unknown", organization: @organization)
    assert_nil value
  end

  test "translate returns translated name" do
    # The fixture has "Full-time" in the translations
    name = LookupService.translate("employment_type", "full_time", organization: @organization)
    # Should match what's in the fixture's translations
    assert_includes ["Full-time", "Full time"], name
  end

  test "translate returns humanized code when not found" do
    name = LookupService.translate("employment_type", "unknown_code", organization: @organization)
    assert_equal "Unknown code", name
  end

  test "values returns lookup value objects" do
    values = LookupService.values("employment_type", organization: @organization)

    assert_kind_of ActiveRecord::Relation, values
    assert values.any?
    assert values.all? { |v| v.is_a?(LookupValue) }
  end

  test "valid_codes returns array of codes" do
    codes = LookupService.valid_codes("employment_type", organization: @organization)

    assert_kind_of Array, codes
    assert_includes codes, "full_time"
    assert_includes codes, "part_time"
  end

  test "valid_code? returns true for valid code" do
    assert LookupService.valid_code?("employment_type", "full_time", organization: @organization)
  end

  test "valid_code? returns false for invalid code" do
    assert_not LookupService.valid_code?("employment_type", "invalid", organization: @organization)
  end

  test "default_value returns default lookup value" do
    value = LookupService.default_value("employment_type", organization: @organization)

    assert_not_nil value
    assert value.is_default?
  end

  test "default_code returns default value code" do
    code = LookupService.default_code("employment_type", organization: @organization)

    assert_not_nil code
    assert_equal "full_time", code
  end
end
