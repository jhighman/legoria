# frozen_string_literal: true

require "test_helper"

class TalentPoolMemberTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    @pool = talent_pools(:engineering_pool)
    @candidate = candidates(:john_doe)
    Current.organization = @organization
    Current.user = users(:admin)
  end

  teardown do
    Current.reset
  end

  # Validations
  test "validates source inclusion" do
    member = TalentPoolMember.new(
      talent_pool: @pool,
      candidate: candidates(:jane_smith),
      source: "invalid"
    )
    assert_not member.valid?
    assert_includes member.errors[:source], "is not included in the list"
  end

  test "validates uniqueness of candidate per pool" do
    existing = talent_pool_members(:john_in_engineering)
    duplicate = TalentPoolMember.new(
      talent_pool: existing.talent_pool,
      candidate: existing.candidate,
      source: "manual"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:candidate_id], "has already been taken"
  end

  # Scopes
  test "by_source filters by source" do
    manual_members = TalentPoolMember.by_source("manual")
    assert_includes manual_members, talent_pool_members(:john_in_engineering)
  end

  test "manually_added returns manual source members" do
    assert_includes TalentPoolMember.manually_added, talent_pool_members(:john_in_engineering)
  end

  # Delegation
  test "delegates organization_id to talent_pool" do
    member = talent_pool_members(:john_in_engineering)
    assert_equal member.talent_pool.organization_id, member.organization_id
  end
end
