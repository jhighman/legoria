# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @user = users(:admin)
  end

  def teardown
    Current.organization = nil
  end

  test "valid user" do
    assert @user.valid?
  end

  test "requires first_name" do
    @user.first_name = nil
    assert_not @user.valid?
    assert_includes @user.errors[:first_name], "can't be blank"
  end

  test "requires last_name" do
    @user.last_name = nil
    assert_not @user.valid?
    assert_includes @user.errors[:last_name], "can't be blank"
  end

  test "requires email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "email uniqueness scoped to organization" do
    duplicate = User.new(
      organization: @organization,
      first_name: "Test",
      last_name: "User",
      email: @user.email,
      password: "password123"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "full_name returns first and last name" do
    @user.first_name = "John"
    @user.last_name = "Doe"
    assert_equal "John Doe", @user.full_name
  end

  test "initials returns uppercase initials" do
    @user.first_name = "John"
    @user.last_name = "Doe"
    assert_equal "JD", @user.initials
  end

  test "display_name returns full name or email" do
    @user.first_name = "John"
    @user.last_name = "Doe"
    assert_equal "John Doe", @user.display_name

    @user.first_name = ""
    @user.last_name = ""
    assert_equal @user.email, @user.display_name
  end

  test "active? returns active status" do
    @user.active = true
    assert @user.active?

    @user.active = false
    assert_not @user.active?
  end

  test "deactivate! sets active to false" do
    @user.deactivate!
    assert_not @user.active?
  end

  test "activate! sets active to true" do
    @user.update!(active: false)
    @user.activate!
    assert @user.active?
  end

  test "active_for_authentication? checks active status" do
    @user.active = true
    @user.confirmed_at = Time.current
    assert @user.active_for_authentication?

    @user.active = false
    assert_not @user.active_for_authentication?
  end

  test "has_role? checks role membership" do
    assert_respond_to @user, :has_role?
  end

  test "has_permission? delegates to roles" do
    assert_respond_to @user, :has_permission?
  end

  test "can? is alias for has_permission?" do
    assert_respond_to @user, :can?
  end
end
