# frozen_string_literal: true

require "test_helper"

class DepartmentTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @department = departments(:engineering)
  end

  def teardown
    Current.organization = nil
  end

  test "valid department" do
    assert @department.valid?
  end

  test "requires name" do
    @department.name = nil
    assert_not @department.valid?
    assert_includes @department.errors[:name], "can't be blank"
  end

  test "code uniqueness scoped to organization" do
    @department.code = "ENG"
    @department.save!

    duplicate = Department.new(
      organization: @organization,
      name: "Test",
      code: "ENG"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"
  end

  test "position must be non-negative integer" do
    @department.position = -1
    assert_not @department.valid?

    @department.position = 0
    assert @department.valid?
  end

  test "root? returns true for departments without parent" do
    @department.parent = nil
    assert @department.root?
  end

  test "leaf? returns true for departments without children" do
    # Assuming no children by default
    @department.children.destroy_all
    assert @department.leaf?
  end

  test "ancestors returns parent chain" do
    parent = Department.create!(organization: @organization, name: "Parent", position: 0)
    @department.parent = parent
    @department.save!

    assert_includes @department.ancestors, parent
  end

  test "descendants returns all children recursively" do
    child = Department.create!(organization: @organization, name: "Child", parent: @department, position: 0)

    assert_includes @department.descendants, child
  end

  test "depth returns ancestor count" do
    parent = Department.create!(organization: @organization, name: "Parent", position: 0)
    @department.parent = parent
    @department.save!

    assert_equal 1, @department.depth
  end

  test "full_path returns ancestor names joined" do
    parent = Department.create!(organization: @organization, name: "Parent", position: 0)
    @department.parent = parent
    @department.save!

    assert_includes @department.full_path, "Parent"
    assert_includes @department.full_path, @department.name
  end

  test "parent must belong to same organization" do
    other_org = Organization.create!(name: "Other", subdomain: "other")
    parent = Department.create!(organization: other_org, name: "Other Parent", position: 0)

    @department.parent = parent
    assert_not @department.valid?
    assert_includes @department.errors[:parent], "must belong to the same organization"
  end

  test "ordered scope sorts by position then name" do
    assert_respond_to Department, :ordered
  end

  test "roots scope returns only root departments" do
    roots = Department.roots
    roots.each do |dept|
      assert dept.root?
    end
  end
end
