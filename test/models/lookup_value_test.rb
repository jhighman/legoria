# frozen_string_literal: true

require "test_helper"

class LookupValueTest < ActiveSupport::TestCase
  def setup
    @lookup_type = lookup_types(:acme_employment_type)
    @lookup_value = lookup_values(:acme_full_time)
  end

  test "valid lookup value" do
    assert @lookup_value.valid?
  end

  test "requires code" do
    @lookup_value.code = nil
    assert_not @lookup_value.valid?
    assert_includes @lookup_value.errors[:code], "can't be blank"
  end

  test "requires translations" do
    @lookup_value.translations = nil
    assert_not @lookup_value.valid?
    assert_includes @lookup_value.errors[:translations], "can't be blank"
  end

  test "code must be lowercase with underscores" do
    @lookup_value.code = "Invalid Code"
    assert_not @lookup_value.valid?
    assert_includes @lookup_value.errors[:code], "must be lowercase with underscores"
  end

  test "code must be unique per lookup type" do
    duplicate = @lookup_type.lookup_values.build(
      code: "full_time",
      translations: { "en" => { "name" => "Duplicate" } }
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"
  end

  test "name returns English translation" do
    @lookup_value.translations = { "en" => { "name" => "Full-time" } }
    assert_equal "Full-time", @lookup_value.name
  end

  test "name falls back to code humanized" do
    @lookup_value.translations = {}
    assert_equal "Full time", @lookup_value.name
  end

  test "description returns from translations" do
    @lookup_value.translations = { "en" => { "name" => "Test", "description" => "Test desc" } }
    assert_equal "Test desc", @lookup_value.description
  end

  test "set_translation updates translations" do
    # Ensure translations is a hash first
    @lookup_value.translations = { "en" => { "name" => "Full-time" } } if @lookup_value.translations.is_a?(String)
    @lookup_value.set_translation(:es, name: "Tiempo completo", description: "Trabajo de tiempo completo")
    assert_equal "Tiempo completo", @lookup_value.translations["es"]["name"]
    assert_equal "Trabajo de tiempo completo", @lookup_value.translations["es"]["description"]
  end

  test "available_locales returns translation keys" do
    @lookup_value.translations = { "en" => { "name" => "Test" }, "es" => { "name" => "Prueba" } }
    assert_includes @lookup_value.available_locales, "en"
    assert_includes @lookup_value.available_locales, "es"
  end

  test "active scope returns only active values" do
    active_values = @lookup_type.lookup_values.active
    assert active_values.all?(&:active?)
  end

  test "ordered scope orders by position and code" do
    values = @lookup_type.lookup_values.ordered
    positions = values.map(&:position)
    assert_equal positions, positions.sort
  end

  test "ensure_single_default unsets other defaults" do
    # First make sure we have a default
    @lookup_value.update!(is_default: true)

    # Create another value and set it as default
    new_value = @lookup_type.lookup_values.create!(
      code: "test_default",
      translations: { "en" => { "name" => "Test" } },
      is_default: true
    )

    @lookup_value.reload
    assert_not @lookup_value.is_default?
    assert new_value.is_default?
  end
end
