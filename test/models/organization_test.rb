# frozen_string_literal: true

require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
  end

  test "valid organization" do
    assert @organization.valid?
  end

  test "requires name" do
    @organization.name = nil
    assert_not @organization.valid?
    assert_includes @organization.errors[:name], "can't be blank"
  end

  test "requires subdomain" do
    @organization.subdomain = nil
    assert_not @organization.valid?
    assert_includes @organization.errors[:subdomain], "can't be blank"
  end

  test "subdomain must be unique" do
    duplicate = Organization.new(name: "Test", subdomain: @organization.subdomain)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:subdomain], "has already been taken"
  end

  test "subdomain format validation" do
    @organization.subdomain = "invalid subdomain"
    assert_not @organization.valid?

    @organization.subdomain = "valid-subdomain"
    assert @organization.valid?
  end

  test "has many users" do
    assert_respond_to @organization, :users
  end

  test "has many departments" do
    assert_respond_to @organization, :departments
  end

  test "has many roles" do
    assert_respond_to @organization, :roles
  end

  test "has many stages" do
    assert_respond_to @organization, :stages
  end

  test "kept scope excludes discarded" do
    kept_count = Organization.kept.count
    @organization.discard!
    assert_equal kept_count - 1, Organization.kept.count
  end

  test "discard! sets discarded_at" do
    @organization.discard!
    assert @organization.discarded?
  end

  test "undiscard! clears discarded_at" do
    @organization.discard!
    @organization.undiscard!
    assert @organization.kept?
  end

  test "trial? returns true for trial plan" do
    @organization.plan = "trial"
    assert @organization.trial?

    @organization.plan = "professional"
    assert_not @organization.trial?
  end

  test "hostname returns domain or subdomain" do
    @organization.domain = "acme.com"
    assert_equal "acme.com", @organization.hostname

    @organization.domain = nil
    assert_includes @organization.hostname, @organization.subdomain
  end
end
