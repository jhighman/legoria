# frozen_string_literal: true

require "test_helper"

class RoleTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @role = roles(:admin)
  end

  def teardown
    Current.organization = nil
  end

  test "valid role" do
    assert @role.valid?
  end

  test "requires name" do
    @role.name = nil
    assert_not @role.valid?
    assert_includes @role.errors[:name], "can't be blank"
  end

  test "name uniqueness scoped to organization" do
    duplicate = Role.new(
      organization: @organization,
      name: @role.name
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "system_roles scope" do
    system_roles = Role.system_roles
    system_roles.each do |role|
      assert role.system_role?
    end
  end

  test "custom_roles scope" do
    custom_roles = Role.custom_roles
    custom_roles.each do |role|
      assert_not role.system_role?
    end
  end

  test "has_permission? returns boolean" do
    assert_respond_to @role, :has_permission?
  end

  test "grant_permission adds permission to json" do
    @role.permissions = {}
    @role.grant_permission("users", "read")
    assert_includes @role.permissions["users"], "read"
  end

  test "revoke_permission removes permission from json" do
    @role.permissions = { "users" => ["read", "write"] }
    @role.revoke_permission("users", "read")
    assert_not_includes @role.permissions["users"], "read"
  end

  test "admin? checks name and system_role" do
    @role.name = "admin"
    @role.system_role = true
    assert @role.admin?

    @role.name = "other"
    assert_not @role.admin?
  end

  test "has many users through user_roles" do
    assert_respond_to @role, :users
  end

  test "has many linked_permissions through role_permissions" do
    assert_respond_to @role, :linked_permissions
  end
end
