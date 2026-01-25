# frozen_string_literal: true

module Reports
  class TimeToHireController < BaseController
    def index
      @data = TimeToHireQuery.call(**filter_params)
      @jobs = Job.kept.order(:title)
      @departments = Department.order(:name)

      respond_to do |format|
        format.html
        format.json { render json: chart_data }
      end
    end

    def export
      authorize :report, :export?

      data = TimeToHireQuery.call(**filter_params)

      csv = generate_csv(data)
      send_csv(csv, "time_to_hire_report")
    end

    private

    def report_title
      "Time to Hire"
    end

    def report_description
      "Average days from application to hire"
    end

    def chart_data
      {
        labels: @data[:trend].map { |t| t[:label] },
        datasets: [
          {
            label: "Average Days to Hire",
            data: @data[:trend].map { |t| t[:average_days] },
            borderColor: "#3B82F6",
            backgroundColor: "rgba(59, 130, 246, 0.1)",
            fill: true
          },
          {
            label: "Hires",
            data: @data[:trend].map { |t| t[:hires] },
            borderColor: "#10B981",
            backgroundColor: "rgba(16, 185, 129, 0.1)",
            yAxisID: "y1"
          }
        ]
      }
    end

    def generate_csv(data)
      require "csv"

      CSV.generate(headers: true) do |csv|
        csv << ["Candidate", "Job", "Source", "Applied Date", "Hired Date", "Days to Hire"]

        data[:raw_data].each do |row|
          csv << [
            row[:candidate_name],
            row[:job_title],
            row[:source],
            row[:applied_at].strftime("%Y-%m-%d"),
            row[:hired_at].strftime("%Y-%m-%d"),
            row[:days_to_hire]
          ]
        end
      end
    end
  end
end
