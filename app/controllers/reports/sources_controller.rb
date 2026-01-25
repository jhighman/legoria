# frozen_string_literal: true

module Reports
  class SourcesController < BaseController
    def index
      @data = SourceEffectivenessQuery.call(**filter_params)
      @jobs = Job.kept.order(:title)
      @departments = Department.order(:name)

      respond_to do |format|
        format.html
        format.json { render json: chart_data }
      end
    end

    def export
      authorize :report, :export?

      data = SourceEffectivenessQuery.call(**filter_params)

      csv = generate_csv(data)
      send_csv(csv, "source_effectiveness_report")
    end

    private

    def report_title
      "Source Effectiveness"
    end

    def report_description
      "Analyze application sources and their conversion rates"
    end

    def chart_data
      sources = @data[:by_source].first(8)

      {
        labels: sources.map { |s| s[:source_label] },
        datasets: [
          {
            label: "Applications",
            data: sources.map { |s| s[:applications] },
            backgroundColor: "#3B82F6"
          },
          {
            label: "Hires",
            data: sources.map { |s| s[:hired] },
            backgroundColor: "#10B981"
          }
        ]
      }
    end

    def generate_csv(data)
      require "csv"

      CSV.generate(headers: true) do |csv|
        csv << [
          "Source", "Applications", "In Progress", "Hired",
          "Rejected", "Conversion Rate", "Quality Score"
        ]

        data[:by_source].each do |row|
          csv << [
            row[:source_label],
            row[:applications],
            row[:in_progress],
            row[:hired],
            row[:rejected],
            "#{row[:conversion_rate]}%",
            row[:quality_score]
          ]
        end
      end
    end
  end
end
