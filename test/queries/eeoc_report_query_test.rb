# frozen_string_literal: true

require "test_helper"

class EeocReportQueryTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
  end

  teardown do
    Current.reset
  end

  test "returns summary metrics" do
    result = EeocReportQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:summary].is_a?(Hash)
    assert_includes result[:summary].keys, :total_applications
    assert_includes result[:summary].keys, :eeoc_responses
    assert_includes result[:summary].keys, :response_rate
  end

  test "returns gender breakdown" do
    result = EeocReportQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:by_gender].is_a?(Array)
  end

  test "returns race_ethnicity breakdown" do
    result = EeocReportQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:by_race_ethnicity].is_a?(Array)
  end

  test "returns disability breakdown" do
    result = EeocReportQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:by_disability_status].is_a?(Array)
  end

  test "returns veteran breakdown" do
    result = EeocReportQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:by_veteran_status].is_a?(Array)
  end
end
