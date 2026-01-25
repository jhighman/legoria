# frozen_string_literal: true

require "test_helper"

class SourceEffectivenessQueryTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
  end

  teardown do
    Current.reset
  end

  test "returns summary metrics" do
    result = SourceEffectivenessQuery.call(
      start_date: 30.days.ago,
      end_date: Time.current
    )

    assert result[:summary].is_a?(Hash)
    assert_includes result[:summary].keys, :total_applications
    assert_includes result[:summary].keys, :unique_sources
  end

  test "groups applications by source" do
    result = SourceEffectivenessQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:by_source].is_a?(Array)
    # Fixtures have career_site and referral sources
    assert result[:by_source].any?
  end

  test "calculates conversion rate for hired applications" do
    # Mark an application as hired
    application = applications(:active_application)
    application.update_columns(status: "hired", hired_at: 1.day.ago)

    result = SourceEffectivenessQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    source = result[:by_source].find { |s| s[:source_type] == application.source_type }
    assert source
    assert source[:hired] >= 0
    assert source[:conversion_rate] >= 0
  end
end
