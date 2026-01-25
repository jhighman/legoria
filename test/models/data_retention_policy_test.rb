# frozen_string_literal: true

require "test_helper"

class DataRetentionPolicyTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @policy = data_retention_policies(:candidate_data_policy)
  end

  def teardown
    Current.organization = nil
  end

  test "valid policy" do
    assert @policy.valid?
  end

  test "requires name" do
    @policy.name = nil
    assert_not @policy.valid?
    assert_includes @policy.errors[:name], "can't be blank"
  end

  test "requires data_category" do
    @policy.data_category = nil
    assert_not @policy.valid?
    assert_includes @policy.errors[:data_category], "can't be blank"
  end

  test "validates data_category inclusion" do
    @policy.data_category = "invalid"
    assert_not @policy.valid?
    assert_includes @policy.errors[:data_category], "is not included in the list"
  end

  test "validates retention_days is positive" do
    @policy.retention_days = 0
    assert_not @policy.valid?
    assert @policy.errors[:retention_days].any?
  end

  test "validates retention_trigger inclusion" do
    @policy.retention_trigger = "invalid"
    assert_not @policy.valid?
    assert_includes @policy.errors[:retention_trigger], "is not included in the list"
  end

  test "validates action_type inclusion" do
    @policy.action_type = "invalid"
    assert_not @policy.valid?
    assert_includes @policy.errors[:action_type], "is not included in the list"
  end

  # Category helpers
  test "candidate_data? returns true for candidate_data policies" do
    assert @policy.candidate_data?
  end

  test "eeoc_data? returns true for eeoc_data policies" do
    assert data_retention_policies(:eeoc_data_policy).eeoc_data?
  end

  # Action helpers
  test "anonymize? returns true for anonymize policies" do
    assert @policy.anonymize?
  end

  test "archive? returns true for archive policies" do
    assert data_retention_policies(:application_data_policy).archive?
  end

  # Display helpers
  test "data_category_label returns formatted category" do
    assert_equal "Candidate Data", @policy.data_category_label
  end

  test "retention_period_label returns formatted period" do
    assert_equal "2 years", @policy.retention_period_label
  end

  # Calculation helpers
  test "calculate_deletion_date adds retention days" do
    trigger_date = Date.current
    deletion_date = @policy.calculate_deletion_date(trigger_date)
    assert_equal trigger_date + 730.days, deletion_date
  end

  test "should_process? returns true when past retention period" do
    assert @policy.should_process?(3.years.ago)
    assert_not @policy.should_process?(1.month.ago)
  end

  # Activation
  test "deactivate! sets active to false" do
    @policy.deactivate!
    assert_not @policy.reload.active?
  end

  test "activate! sets active to true" do
    inactive = data_retention_policies(:inactive_policy)
    inactive.activate!
    assert inactive.reload.active?
  end

  # Scopes
  test "active scope returns only active policies" do
    active = DataRetentionPolicy.active
    active.each { |p| assert p.active? }
  end

  test "by_category scope filters by data category" do
    candidate = DataRetentionPolicy.by_category("candidate_data")
    candidate.each { |p| assert p.candidate_data? }
  end
end
