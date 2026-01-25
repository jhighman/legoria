# frozen_string_literal: true

require "test_helper"

class JobTemplateTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @template = job_templates(:engineer_template)
  end

  def teardown
    Current.organization = nil
  end

  test "valid job template" do
    assert @template.valid?
  end

  test "requires name" do
    @template.name = nil
    assert_not @template.valid?
    assert_includes @template.errors[:name], "can't be blank"
  end

  test "requires title" do
    @template.title = nil
    assert_not @template.valid?
    assert_includes @template.errors[:title], "can't be blank"
  end

  test "name must be unique within organization" do
    duplicate = JobTemplate.new(
      organization: @organization,
      name: @template.name,
      title: "Test"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "requires valid employment_type" do
    @template.employment_type = "invalid"
    assert_not @template.valid?
  end

  test "requires valid location_type" do
    @template.location_type = "invalid"
    assert_not @template.valid?
  end

  test "default_headcount must be positive" do
    @template.default_headcount = 0
    assert_not @template.valid?

    @template.default_headcount = 1
    assert @template.valid?
  end

  test "salary_max must be >= salary_min" do
    @template.salary_min = 100000
    @template.salary_max = 50000
    assert_not @template.valid?
  end

  test "build_job creates job from template attributes" do
    job = @template.build_job

    assert_equal @template.title, job.title
    assert_equal @template.description, job.description
    assert_equal @template.requirements, job.requirements
    assert_equal @template.location_type, job.location_type
    assert_equal @template.employment_type, job.employment_type
    assert_equal @template.default_headcount, job.headcount
    assert_equal @template.department, job.department
  end

  test "build_job allows overriding attributes" do
    job = @template.build_job(title: "Custom Title", headcount: 5)

    assert_equal "Custom Title", job.title
    assert_equal 5, job.headcount
  end

  test "active scope returns only active templates" do
    JobTemplate.active.each do |template|
      assert template.active
    end
  end

  test "inactive scope returns only inactive templates" do
    JobTemplate.inactive.each do |template|
      assert_not template.active
    end
  end

  test "activate! sets active to true" do
    @template = job_templates(:inactive_template)
    @template.activate!
    assert @template.active
  end

  test "deactivate! sets active to false" do
    @template.deactivate!
    assert_not @template.active
  end
end
