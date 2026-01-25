# frozen_string_literal: true

require "test_helper"

class I9ComplianceQueryTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
  end

  teardown do
    Current.reset
  end

  test "returns summary metrics" do
    result = I9ComplianceQuery.call(
      start_date: 30.days.ago.to_date,
      end_date: Date.current
    )

    assert_includes result.keys, :summary
    summary = result[:summary]
    assert_includes summary.keys, :total_verifications
    assert_includes summary.keys, :verified
    assert_includes summary.keys, :pending
    assert_includes summary.keys, :completion_rate
    assert_includes summary.keys, :late_rate
  end

  test "returns completion rate metrics" do
    result = I9ComplianceQuery.call(
      start_date: 30.days.ago.to_date,
      end_date: Date.current
    )

    assert_includes result.keys, :completion_rates
    rates = result[:completion_rates]
    assert_includes rates.keys, :section1_completion_rate
    assert_includes rates.keys, :section2_completion_rate
  end

  test "returns timing metrics" do
    result = I9ComplianceQuery.call(
      start_date: 30.days.ago.to_date,
      end_date: Date.current
    )

    assert_includes result.keys, :timing_metrics
    timing = result[:timing_metrics]
    assert_includes timing.keys, :avg_section1_hours
    assert_includes timing.keys, :avg_section2_hours
    assert_includes timing.keys, :avg_total_hours
  end

  test "returns metrics by status" do
    result = I9ComplianceQuery.call(
      start_date: 30.days.ago.to_date,
      end_date: Date.current
    )

    assert_includes result.keys, :by_status
    assert result[:by_status].is_a?(Array)
  end

  test "returns metrics by department" do
    result = I9ComplianceQuery.call(
      start_date: 30.days.ago.to_date,
      end_date: Date.current
    )

    assert_includes result.keys, :by_department
    assert result[:by_department].is_a?(Array)
  end

  test "returns pending deadlines data" do
    result = I9ComplianceQuery.call(
      start_date: 30.days.ago.to_date,
      end_date: Date.current
    )

    assert_includes result.keys, :pending_deadlines
    deadlines = result[:pending_deadlines]
    assert_includes deadlines.keys, :due_today
    assert_includes deadlines.keys, :due_this_week
    assert_includes deadlines.keys, :due_next_week
  end

  test "returns overdue data" do
    result = I9ComplianceQuery.call(
      start_date: 30.days.ago.to_date,
      end_date: Date.current
    )

    assert_includes result.keys, :overdue
    overdue = result[:overdue]
    assert_includes overdue.keys, :count
    assert_includes overdue.keys, :verifications
  end

  test "returns late completion data" do
    result = I9ComplianceQuery.call(
      start_date: 30.days.ago.to_date,
      end_date: Date.current
    )

    assert_includes result.keys, :late_completions
    late = result[:late_completions]
    assert_includes late.keys, :count
    assert_includes late.keys, :verifications
  end

  test "returns trend data" do
    result = I9ComplianceQuery.call(
      start_date: 30.days.ago.to_date,
      end_date: Date.current
    )

    assert_includes result.keys, :trend
    assert result[:trend].is_a?(Array)
  end

  test "returns raw data" do
    result = I9ComplianceQuery.call(
      start_date: 30.days.ago.to_date,
      end_date: Date.current
    )

    assert_includes result.keys, :raw_data
    assert result[:raw_data].is_a?(Array)
  end

  test "filters by status" do
    result = I9ComplianceQuery.call(
      start_date: 30.days.ago.to_date,
      end_date: Date.current,
      status: "verified"
    )

    assert result[:raw_data].all? { |v| v[:status] == "verified" }
  end

  test "filters by department" do
    department = departments(:engineering)
    result = I9ComplianceQuery.call(
      start_date: 30.days.ago.to_date,
      end_date: Date.current,
      department_id: department.id
    )

    # Should not error
    assert_includes result.keys, :summary
  end

  test "scopes to current organization" do
    # This test verifies that the query only returns verifications
    # for the current organization
    result = I9ComplianceQuery.call(
      start_date: 30.days.ago.to_date,
      end_date: Date.current
    )

    # All returned verifications should belong to current organization
    result[:raw_data].each do |v|
      verification = I9Verification.find(v[:id])
      assert_equal @organization.id, verification.organization_id
    end
  end
end
