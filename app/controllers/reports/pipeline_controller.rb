# frozen_string_literal: true

module Reports
  class PipelineController < BaseController
    def index
      @data = PipelineConversionQuery.call(**filter_params)
      @jobs = Job.kept.order(:title)
      @departments = Department.order(:name)

      respond_to do |format|
        format.html
        format.json { render json: chart_data }
      end
    end

    def export
      authorize :report, :export?

      data = PipelineConversionQuery.call(**filter_params)

      csv = generate_csv(data)
      send_csv(csv, "pipeline_conversion_report")
    end

    private

    def report_title
      "Pipeline Conversion"
    end

    def report_description
      "Stage-to-stage conversion rates and funnel analysis"
    end

    def chart_data
      {
        labels: @data[:funnel].map { |s| s[:stage_name] },
        datasets: [{
          label: "Candidates",
          data: @data[:funnel].map { |s| s[:entries] },
          backgroundColor: @data[:funnel].map { |s| s[:stage_color] || "#6B7280" }
        }]
      }
    end

    def generate_csv(data)
      require "csv"

      CSV.generate(headers: true) do |csv|
        csv << [
          "Stage", "Entries", "Exits", "Rejections",
          "Pass-Through Rate", "Rejection Rate", "Avg Time (hours)"
        ]

        data[:stage_metrics].each do |row|
          csv << [
            row[:stage_name],
            row[:entries],
            row[:exits],
            row[:rejections],
            "#{row[:pass_through_rate]}%",
            "#{row[:rejection_rate]}%",
            row[:avg_time_hours]&.round(1)
          ]
        end
      end
    end
  end
end
