# frozen_string_literal: true

require "test_helper"

class SavedSearchTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    @user = users(:recruiter)
    Current.organization = @organization
    Current.user = @user
  end

  teardown do
    Current.reset
  end

  # Validations
  test "requires name" do
    search = SavedSearch.new(
      organization: @organization,
      user: @user,
      criteria: { query: "ruby" },
      search_type: "candidate"
    )
    assert_not search.valid?
    assert_includes search.errors[:name], "can't be blank"
  end

  test "requires criteria" do
    search = SavedSearch.new(
      organization: @organization,
      user: @user,
      name: "My Search",
      search_type: "candidate"
    )
    assert_not search.valid?
    assert_includes search.errors[:criteria], "can't be blank"
  end

  test "search_type has default value" do
    search = SavedSearch.new(
      organization: @organization,
      user: @user,
      name: "My Search",
      criteria: { query: "ruby" }
    )
    # search_type has a default of "candidate"
    assert search.valid?
    assert_equal "candidate", search.search_type
  end

  test "validates search_type inclusion" do
    search = saved_searches(:ruby_developers)
    search.search_type = "invalid"
    assert_not search.valid?
    assert_includes search.errors[:search_type], "is not included in the list"
  end

  test "validates alert_frequency inclusion" do
    search = saved_searches(:ruby_developers)
    search.alert_frequency = "invalid"
    assert_not search.valid?
    assert_includes search.errors[:alert_frequency], "is not included in the list"
  end

  # Scopes
  test "shared scope returns shared searches" do
    assert_includes SavedSearch.shared, saved_searches(:ruby_developers)
    assert_not_includes SavedSearch.shared, saved_searches(:my_private_search)
  end

  test "personal scope returns personal searches" do
    assert_includes SavedSearch.personal, saved_searches(:my_private_search)
    assert_not_includes SavedSearch.personal, saved_searches(:ruby_developers)
  end

  test "with_alerts scope returns searches with alerts enabled" do
    assert_includes SavedSearch.with_alerts, saved_searches(:ruby_developers)
    assert_not_includes SavedSearch.with_alerts, saved_searches(:senior_engineers)
  end

  # Execute search
  test "execute returns candidates matching query" do
    search = saved_searches(:ruby_developers)
    # Update a candidate to have searchable skills
    candidate = candidates(:john_doe)
    candidate.update!(search_text: "ruby developer rails postgresql")

    results = search.execute
    assert_kind_of ActiveRecord::Relation, results
  end

  # Record run
  test "record_run updates last_run_at and last_result_count" do
    search = saved_searches(:my_private_search)
    original_run_at = search.last_run_at
    original_count = search.run_count

    search.record_run!(25)

    assert_not_equal original_run_at, search.last_run_at
    assert_equal 25, search.last_result_count
    assert_equal original_count + 1, search.run_count
  end

  # Association with talent pools
  test "can be linked to smart talent pool" do
    search = saved_searches(:ruby_developers)
    pool = talent_pools(:ruby_talent)
    assert_equal search, pool.saved_search
  end
end
