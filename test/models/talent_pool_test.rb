# frozen_string_literal: true

require "test_helper"

class TalentPoolTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    @user = users(:recruiter)
    @candidate = candidates(:john_doe)
    Current.organization = @organization
    Current.user = @user
  end

  teardown do
    Current.reset
  end

  # Validations
  test "requires name" do
    pool = TalentPool.new(
      organization: @organization,
      owner: @user,
      pool_type: "manual"
    )
    assert_not pool.valid?
    assert_includes pool.errors[:name], "can't be blank"
  end

  test "pool_type has default value" do
    pool = TalentPool.new(
      organization: @organization,
      owner: @user,
      name: "Test Pool"
    )
    # pool_type has a default of "manual"
    assert pool.valid?
    assert_equal "manual", pool.pool_type
  end

  test "validates pool_type inclusion" do
    pool = talent_pools(:engineering_pool)
    pool.pool_type = "invalid"
    assert_not pool.valid?
    assert_includes pool.errors[:pool_type], "is not included in the list"
  end

  # Type checks
  test "manual? returns true for manual pools" do
    pool = talent_pools(:engineering_pool)
    assert pool.manual?
    assert_not pool.smart?
  end

  test "smart? returns true for smart pools" do
    pool = talent_pools(:ruby_talent)
    assert pool.smart?
    assert_not pool.manual?
  end

  # Add/remove candidates
  test "add_candidate adds candidate to pool" do
    pool = talent_pools(:inactive_pool)
    initial_count = pool.candidates_count

    pool.add_candidate(@candidate, added_by: @user, notes: "Test note")

    assert_includes pool.candidates, @candidate
    assert_equal initial_count + 1, pool.reload.candidates_count
  end

  test "add_candidate does not duplicate existing member" do
    pool = talent_pools(:engineering_pool)
    existing_candidate = candidates(:john_doe)
    initial_count = pool.candidates_count

    pool.add_candidate(existing_candidate)

    assert_equal initial_count, pool.reload.candidates_count
  end

  test "remove_candidate removes candidate from pool" do
    pool = talent_pools(:engineering_pool)
    candidate = candidates(:john_doe)
    initial_count = pool.candidates_count

    pool.remove_candidate(candidate)

    assert_not_includes pool.candidates, candidate
    assert_equal initial_count - 1, pool.reload.candidates_count
  end

  # Activate/deactivate
  test "deactivate sets active to false" do
    pool = talent_pools(:engineering_pool)
    assert pool.active?
    pool.deactivate!
    assert_not pool.active?
  end

  test "activate sets active to true" do
    pool = talent_pools(:inactive_pool)
    assert_not pool.active?
    pool.activate!
    assert pool.active?
  end

  # Scopes
  test "active scope returns active pools" do
    assert_includes TalentPool.active, talent_pools(:engineering_pool)
    assert_not_includes TalentPool.active, talent_pools(:inactive_pool)
  end

  test "manual scope returns manual pools" do
    assert_includes TalentPool.manual, talent_pools(:engineering_pool)
    assert_not_includes TalentPool.manual, talent_pools(:ruby_talent)
  end

  test "smart scope returns smart pools" do
    assert_includes TalentPool.smart, talent_pools(:ruby_talent)
    assert_not_includes TalentPool.smart, talent_pools(:engineering_pool)
  end

  test "shared scope returns shared pools" do
    assert_includes TalentPool.shared, talent_pools(:engineering_pool)
    assert_not_includes TalentPool.shared, talent_pools(:inactive_pool)
  end
end
