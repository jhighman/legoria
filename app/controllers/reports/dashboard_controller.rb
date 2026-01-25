# frozen_string_literal: true

module Reports
  class DashboardController < BaseController
    def index
      @time_to_hire = TimeToHireQuery.call(**quick_filter_params)
      @source_effectiveness = SourceEffectivenessQuery.call(**quick_filter_params)
      @pipeline = PipelineConversionQuery.call(**quick_filter_params)
    end

    private

    def quick_filter_params
      {
        start_date: 30.days.ago.beginning_of_day,
        end_date: Time.current.end_of_day
      }
    end
  end
end
