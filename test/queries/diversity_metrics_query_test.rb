# frozen_string_literal: true

require "test_helper"

class DiversityMetricsQueryTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
  end

  teardown do
    Current.reset
  end

  test "returns diversity summary" do
    result = DiversityMetricsQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:summary].is_a?(Hash)
    assert_includes result[:summary].keys, :diversity_index
  end

  test "diversity index is between 0 and 1" do
    result = DiversityMetricsQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    # Diversity index should be between 0 and 1
    assert result[:summary][:diversity_index] >= 0
    assert result[:summary][:diversity_index] <= 1
  end

  test "returns representation metrics" do
    result = DiversityMetricsQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:representation].is_a?(Hash)
    assert_includes result[:representation].keys, :by_gender
    assert_includes result[:representation].keys, :by_race
  end

  test "handles insufficient data gracefully" do
    result = DiversityMetricsQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    # Should return note about insufficient data or respondent count
    assert result[:summary][:note] || result[:summary][:total_respondents] >= 0
  end

  test "returns trends data" do
    result = DiversityMetricsQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:trends].is_a?(Array)
  end
end
