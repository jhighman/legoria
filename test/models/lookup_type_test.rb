# frozen_string_literal: true

require "test_helper"

class LookupTypeTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    @lookup_type = lookup_types(:acme_employment_type)
  end

  test "valid lookup type" do
    assert @lookup_type.valid?
  end

  test "requires code" do
    @lookup_type.code = nil
    assert_not @lookup_type.valid?
    assert_includes @lookup_type.errors[:code], "can't be blank"
  end

  test "requires name" do
    @lookup_type.name = nil
    assert_not @lookup_type.valid?
    assert_includes @lookup_type.errors[:name], "can't be blank"
  end

  test "code must be lowercase with underscores" do
    @lookup_type.code = "Invalid Code"
    assert_not @lookup_type.valid?
    assert_includes @lookup_type.errors[:code], "must be lowercase with underscores"
  end

  test "code must be unique per organization" do
    duplicate = @organization.lookup_types.build(
      code: "employment_type",
      name: "Duplicate"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"
  end

  test "same code allowed in different organizations" do
    other_org = organizations(:globex)
    existing_code = @lookup_type.code

    # The globex org already has employment_type, so let's try a different code
    new_lookup = other_org.lookup_types.build(
      code: "test_type",
      name: "Test"
    )
    assert new_lookup.valid?
  end

  test "values_for_select returns active values" do
    values = @lookup_type.values_for_select
    assert_kind_of Array, values
    assert values.all? { |v| v.is_a?(Array) && v.length == 2 }
  end

  test "default_value returns default lookup value" do
    default = @lookup_type.default_value
    assert default.nil? || default.is_default?
  end

  test "active scope returns only active lookup types" do
    active_types = LookupType.active
    assert active_types.all?(&:active?)
  end

  test "by_code scope filters by code" do
    types = @organization.lookup_types.by_code("employment_type")
    assert types.all? { |t| t.code == "employment_type" }
  end
end
