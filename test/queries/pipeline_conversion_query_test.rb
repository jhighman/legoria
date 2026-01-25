# frozen_string_literal: true

require "test_helper"

class PipelineConversionQueryTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
  end

  teardown do
    Current.reset
  end

  test "returns funnel data for stages" do
    result = PipelineConversionQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:funnel].is_a?(Array)
    assert result[:stage_metrics].is_a?(Array)
  end

  test "includes stage information in funnel" do
    result = PipelineConversionQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    # Each funnel item should have stage info
    if result[:funnel].any?
      first_stage = result[:funnel].first
      assert first_stage.key?(:stage_id)
      assert first_stage.key?(:stage_name)
    end
  end

  test "identifies bottlenecks" do
    result = PipelineConversionQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    assert result[:bottlenecks].is_a?(Array)
  end

  test "calculates stage metrics" do
    result = PipelineConversionQuery.call(
      start_date: 60.days.ago,
      end_date: Time.current
    )

    # Each stage metric should have relevant data
    if result[:stage_metrics].any?
      first_metric = result[:stage_metrics].first
      assert first_metric.key?(:stage_id)
      assert first_metric.key?(:current_count)
    end
  end
end
