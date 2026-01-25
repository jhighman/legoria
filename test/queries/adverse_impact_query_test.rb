# frozen_string_literal: true

require "test_helper"

class AdverseImpactQueryTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
  end

  teardown do
    Current.reset
  end

  test "returns impact summary" do
    result = AdverseImpactQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:summary].is_a?(Hash)
    assert_includes result[:summary].keys, :adverse_impact_detected
    assert_includes result[:summary].keys, :total_applications
  end

  test "returns selection rates by race" do
    result = AdverseImpactQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:by_race].is_a?(Array)
  end

  test "returns selection rates by gender" do
    result = AdverseImpactQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:by_gender].is_a?(Array)
  end

  test "includes methodology information" do
    result = AdverseImpactQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:methodology].is_a?(Hash)
    assert_includes result[:methodology].keys, :rule
    assert_includes result[:methodology].keys, :description
    assert_includes result[:methodology].keys, :disclaimer
  end

  test "generates recommendations" do
    result = AdverseImpactQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:recommendations].is_a?(Array)
    assert result[:recommendations].first.is_a?(Hash) if result[:recommendations].any?
  end

  test "adverse_impact_detected is a boolean" do
    result = AdverseImpactQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert [true, false].include?(result[:summary][:adverse_impact_detected])
  end
end
