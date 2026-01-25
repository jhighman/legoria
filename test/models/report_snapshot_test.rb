# frozen_string_literal: true

require "test_helper"

class ReportSnapshotTest < ActiveSupport::TestCase
  setup do
    @organization = create(:organization)
    Current.organization = @organization
  end

  teardown do
    Current.reset
  end

  test "valid report snapshot" do
    snapshot = build(:report_snapshot, organization: @organization)
    assert snapshot.valid?
  end

  test "requires organization" do
    Current.reset
    snapshot = build(:report_snapshot, organization: nil)
    assert_not snapshot.valid?
    assert snapshot.errors[:organization].any? || snapshot.errors[:organization_id].any?
  end

  test "requires report_type" do
    snapshot = build(:report_snapshot, organization: @organization, report_type: nil)
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:report_type], "can't be blank"
  end

  test "validates report_type inclusion" do
    snapshot = build(:report_snapshot, organization: @organization, report_type: "invalid")
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:report_type], "is not included in the list"
  end

  test "requires period_type" do
    snapshot = build(:report_snapshot, organization: @organization, period_type: nil)
    assert_not snapshot.valid?
  end

  test "validates period_type inclusion" do
    snapshot = build(:report_snapshot, organization: @organization, period_type: "invalid")
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:period_type], "is not included in the list"
  end

  test "requires period_start" do
    snapshot = build(:report_snapshot, organization: @organization, period_start: nil)
    assert_not snapshot.valid?
  end

  test "requires period_end" do
    snapshot = build(:report_snapshot, organization: @organization, period_end: nil)
    assert_not snapshot.valid?
  end

  test "period_end must be after period_start" do
    snapshot = build(:report_snapshot,
      organization: @organization,
      period_start: Date.current,
      period_end: 1.week.ago.to_date
    )
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:period_end], "must be after period start"
  end

  test "requires generated_at" do
    snapshot = build(:report_snapshot, organization: @organization, generated_at: nil)
    assert_not snapshot.valid?
  end

  test "period_label for daily" do
    snapshot = build(:report_snapshot, :daily, organization: @organization)
    assert_match(/\w+ \d+, \d{4}/, snapshot.period_label)
  end

  test "period_label for weekly" do
    snapshot = build(:report_snapshot, :weekly, organization: @organization)
    assert_match(/Week of/, snapshot.period_label)
  end

  test "period_label for monthly" do
    snapshot = build(:report_snapshot,
      organization: @organization,
      period_type: "monthly",
      period_start: Date.new(2024, 1, 1),
      period_end: Date.new(2024, 1, 31)
    )
    assert_equal "January 2024", snapshot.period_label
  end

  test "stale? returns true for old snapshots" do
    snapshot = create(:report_snapshot, :daily,
      organization: @organization,
      generated_at: 2.days.ago
    )
    assert snapshot.stale?
  end

  test "stale? returns false for recent snapshots" do
    snapshot = create(:report_snapshot, :daily,
      organization: @organization,
      generated_at: 1.hour.ago
    )
    assert_not snapshot.stale?
  end

  test "scope by_type" do
    create(:report_snapshot, organization: @organization, report_type: "eeoc")
    create(:report_snapshot, organization: @organization, report_type: "diversity")

    eeoc_snapshots = ReportSnapshot.by_type("eeoc")
    assert_equal 1, eeoc_snapshots.count
    assert_equal "eeoc", eeoc_snapshots.first.report_type
  end

  test "scope by_period_type" do
    create(:report_snapshot, organization: @organization, period_type: "daily")
    create(:report_snapshot, organization: @organization, period_type: "weekly")

    daily_snapshots = ReportSnapshot.by_period_type("daily")
    assert_equal 1, daily_snapshots.count
    assert_equal "daily", daily_snapshots.first.period_type
  end
end
