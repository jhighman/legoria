# frozen_string_literal: true

require "test_helper"

class CandidateSkillTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    @candidate = candidates(:john_doe)
    Current.organization = @organization
    Current.user = users(:admin)
  end

  teardown do
    Current.reset
  end

  # Validations
  test "requires name" do
    skill = CandidateSkill.new(
      organization: @organization,
      candidate: @candidate,
      source: "parsed"
    )
    assert_not skill.valid?
    assert_includes skill.errors[:name], "can't be blank"
  end

  test "validates source inclusion" do
    skill = CandidateSkill.new(
      organization: @organization,
      candidate: @candidate,
      name: "Ruby",
      source: "invalid"
    )
    assert_not skill.valid?
    assert_includes skill.errors[:source], "is not included in the list"
  end

  test "validates category inclusion" do
    skill = candidate_skills(:john_ruby)
    skill.category = "invalid"
    assert_not skill.valid?
    assert_includes skill.errors[:category], "is not included in the list"
  end

  test "validates proficiency_level inclusion" do
    skill = candidate_skills(:john_ruby)
    skill.proficiency_level = "invalid"
    assert_not skill.valid?
    assert_includes skill.errors[:proficiency_level], "is not included in the list"
  end

  test "validates uniqueness of name per candidate" do
    existing_skill = candidate_skills(:john_ruby)
    duplicate = CandidateSkill.new(
      organization: @organization,
      candidate: existing_skill.candidate,
      name: existing_skill.name,
      source: "self_reported"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  # Callbacks
  test "sets normalized_name before validation" do
    skill = CandidateSkill.new(
      organization: @organization,
      candidate: @candidate,
      name: "  Ruby on Rails  ",
      source: "parsed"
    )
    skill.valid?
    assert_equal "ruby on rails", skill.normalized_name
  end

  # Methods
  test "verify marks skill as verified" do
    skill = candidate_skills(:john_postgresql)
    assert_not skill.verified?
    skill.verify!
    assert skill.verified?
  end

  # Scopes
  test "by_category filters by category" do
    technical_skills = CandidateSkill.by_category("technical")
    assert_includes technical_skills, candidate_skills(:john_ruby)
    assert_not_includes technical_skills, candidate_skills(:jane_communication)
  end

  test "verified scope returns verified skills" do
    assert_includes CandidateSkill.verified, candidate_skills(:john_ruby)
    assert_not_includes CandidateSkill.verified, candidate_skills(:john_postgresql)
  end

  test "unverified scope returns unverified skills" do
    assert_includes CandidateSkill.unverified, candidate_skills(:john_postgresql)
    assert_not_includes CandidateSkill.unverified, candidate_skills(:john_ruby)
  end
end
