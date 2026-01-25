# frozen_string_literal: true

require "test_helper"

class JobRequirementTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    @job = jobs(:draft_job)
    Current.organization = @organization
    Current.user = users(:admin)
  end

  teardown do
    Current.reset
  end

  # Validations
  test "requires requirement_type" do
    req = JobRequirement.new(
      organization: @organization,
      job: @job,
      name: "Ruby",
      importance: "required",
      weight: 5
    )
    assert_not req.valid?
    assert_includes req.errors[:requirement_type], "can't be blank"
  end

  test "validates requirement_type inclusion" do
    req = job_requirements(:ruby_required)
    req.requirement_type = "invalid"
    assert_not req.valid?
    assert_includes req.errors[:requirement_type], "is not included in the list"
  end

  test "requires name" do
    req = JobRequirement.new(
      organization: @organization,
      job: @job,
      requirement_type: "skill",
      importance: "required",
      weight: 5
    )
    assert_not req.valid?
    assert_includes req.errors[:name], "can't be blank"
  end

  test "importance has default value" do
    req = JobRequirement.new(
      organization: @organization,
      job: @job,
      name: "Ruby",
      requirement_type: "skill",
      weight: 5
    )
    # importance has a default of "required"
    assert req.valid?
    assert_equal "required", req.importance
  end

  test "validates importance inclusion" do
    req = job_requirements(:ruby_required)
    req.importance = "invalid"
    assert_not req.valid?
    assert_includes req.errors[:importance], "is not included in the list"
  end

  test "validates weight range" do
    req = job_requirements(:ruby_required)

    req.weight = 0
    assert_not req.valid?

    req.weight = 11
    assert_not req.valid?

    req.weight = 5
    assert req.valid?
  end

  test "validates education_level inclusion" do
    req = job_requirements(:bachelor_degree)
    req.education_level = "invalid"
    assert_not req.valid?
    assert_includes req.errors[:education_level], "is not included in the list"
  end

  # Callbacks
  test "sets normalized_name before validation" do
    req = JobRequirement.new(
      organization: @organization,
      job: @job,
      name: "  Ruby on Rails  ",
      requirement_type: "skill",
      importance: "required",
      weight: 5
    )
    req.valid?
    assert_equal "ruby on rails", req.normalized_name
  end

  test "sets default position" do
    req = JobRequirement.create!(
      organization: @organization,
      job: @job,
      name: "New Skill",
      requirement_type: "skill",
      importance: "required",
      weight: 5
    )
    assert req.position >= 0
  end

  # Type checks
  test "skill? returns true for skill type" do
    req = job_requirements(:ruby_required)
    assert req.skill?
    assert_not req.experience?
  end

  test "experience? returns true for experience type" do
    req = job_requirements(:experience_5_years)
    assert req.experience?
    assert_not req.skill?
  end

  test "education? returns true for education type" do
    req = job_requirements(:bachelor_degree)
    assert req.education?
  end

  # Importance checks
  test "required? returns true for required importance" do
    req = job_requirements(:ruby_required)
    assert req.required?
    assert_not req.preferred?
  end

  test "preferred? returns true for preferred importance" do
    req = job_requirements(:postgresql_preferred)
    assert req.preferred?
    assert_not req.required?
  end

  test "nice_to_have? returns true for nice_to_have importance" do
    req = job_requirements(:kubernetes_nice)
    assert req.nice_to_have?
  end

  # Scopes
  test "by_type filters by requirement_type" do
    skills = JobRequirement.by_type("skill")
    assert_includes skills, job_requirements(:ruby_required)
    assert_not_includes skills, job_requirements(:experience_5_years)
  end

  test "required scope returns required importance" do
    required = JobRequirement.required
    assert_includes required, job_requirements(:ruby_required)
    assert_not_includes required, job_requirements(:postgresql_preferred)
  end

  test "skills scope returns skill types" do
    skills = JobRequirement.skills
    assert_includes skills, job_requirements(:ruby_required)
    assert_not_includes skills, job_requirements(:experience_5_years)
  end

  # met_by? checks
  test "skill requirement met_by candidate with matching skill" do
    req = job_requirements(:ruby_required)
    candidate = candidates(:john_doe)
    assert req.met_by?(candidate)
  end

  test "skill requirement not met by candidate without skill" do
    req = job_requirements(:kubernetes_nice)
    candidate = candidates(:john_doe)
    assert_not req.met_by?(candidate)
  end

  test "experience requirement met by candidate with enough years" do
    req = job_requirements(:experience_5_years)
    candidate = candidates(:john_doe)
    candidate.update!(years_experience: 8)
    assert req.met_by?(candidate)
  end

  test "experience requirement not met by candidate with insufficient years" do
    req = job_requirements(:experience_5_years)
    candidate = candidates(:john_doe)
    candidate.update!(years_experience: 3)
    assert_not req.met_by?(candidate)
  end
end
