# frozen_string_literal: true

module Reports
  class I9ComplianceController < BaseController
    def index
      @data = I9ComplianceQuery.call(**i9_filter_params)
      @departments = Department.order(:name)
      @statuses = I9Verification::STATUSES

      respond_to do |format|
        format.html
        format.json { render json: chart_data }
      end
    end

    def export
      authorize :report, :export?

      data = I9ComplianceQuery.call(**i9_filter_params)

      csv = generate_csv(data)
      send_csv(csv, "i9_compliance_report")
    end

    def pdf
      authorize :report, :export?

      data = I9ComplianceQuery.call(**i9_filter_params)

      pdf = generate_pdf(data)
      send_pdf(pdf, "i9_compliance_report")
    end

    private

    def report_title
      "I-9 Compliance"
    end

    def report_description
      "I-9 verification completion rates and compliance metrics"
    end

    def i9_filter_params
      {
        start_date: start_date,
        end_date: end_date,
        status: params[:status].presence,
        department_id: params[:department_id].presence
      }.compact
    end

    def chart_data
      {
        status_distribution: {
          labels: @data[:by_status].map { |s| s[:status_label] },
          datasets: [{
            data: @data[:by_status].map { |s| s[:count] },
            backgroundColor: status_colors
          }]
        },
        completion_trend: {
          labels: @data[:trend].map { |t| t[:label] },
          datasets: [
            {
              label: "Total I-9s",
              data: @data[:trend].map { |t| t[:total] },
              borderColor: "#3B82F6",
              backgroundColor: "rgba(59, 130, 246, 0.1)",
              fill: true
            },
            {
              label: "Verified",
              data: @data[:trend].map { |t| t[:verified] },
              borderColor: "#10B981",
              backgroundColor: "rgba(16, 185, 129, 0.1)"
            },
            {
              label: "Late",
              data: @data[:trend].map { |t| t[:late] },
              borderColor: "#EF4444",
              backgroundColor: "rgba(239, 68, 68, 0.1)"
            }
          ]
        },
        department_completion: {
          labels: @data[:by_department].map { |d| d[:department_name] },
          datasets: [{
            label: "Completion Rate (%)",
            data: @data[:by_department].map { |d| d[:completion_rate] },
            backgroundColor: "#3B82F6"
          }]
        }
      }
    end

    def status_colors
      [
        "#FCD34D", # pending_section1 - yellow
        "#60A5FA", # section1_complete - blue
        "#A78BFA", # pending_section2 - purple
        "#34D399", # section2_complete - green
        "#F472B6", # pending_everify - pink
        "#FB923C", # everify_tnc - orange
        "#10B981", # verified - emerald
        "#EF4444", # failed - red
        "#6B7280"  # expired - gray
      ]
    end

    def generate_csv(data)
      require "csv"

      CSV.generate(headers: true) do |csv|
        csv << ["Candidate", "Job", "Status", "Created Date", "Deadline",
                "Section 1 Completed", "Section 2 Completed", "Late", "Days to Complete"]

        data[:raw_data].each do |row|
          csv << [
            row[:candidate_name],
            row[:job_title],
            row[:status].titleize,
            row[:created_at]&.strftime("%Y-%m-%d"),
            row[:deadline_section2]&.strftime("%Y-%m-%d"),
            row[:section1_completed_at]&.strftime("%Y-%m-%d"),
            row[:section2_completed_at]&.strftime("%Y-%m-%d"),
            row[:late_completion] ? "Yes" : "No",
            row[:days_to_complete]
          ]
        end
      end
    end

    def generate_pdf(data)
      require "prawn"
      require "prawn/table"

      Prawn::Document.new do |pdf|
        pdf_header(pdf, "I-9 Compliance Report", "#{start_date.strftime('%B %d, %Y')} - #{end_date.strftime('%B %d, %Y')}")

        # Summary metrics
        pdf.text "Summary", size: 16, style: :bold
        pdf.move_down 10

        summary_data = [
          ["Total Verifications", data[:summary][:total_verifications]],
          ["Verified", data[:summary][:verified]],
          ["Pending", data[:summary][:pending]],
          ["Failed/Expired", data[:summary][:failed]],
          ["Late Completions", data[:summary][:late_completions]],
          ["Completion Rate", "#{data[:summary][:completion_rate]}%"],
          ["Late Rate", "#{data[:summary][:late_rate]}%"]
        ]

        pdf.table(summary_data, width: pdf.bounds.width / 2) do
          cells.padding = 8
          cells.borders = [:bottom]
          row(0).font_style = :bold
        end

        pdf.move_down 20

        # Timing metrics
        pdf.text "Timing Metrics", size: 16, style: :bold
        pdf.move_down 10

        timing_data = [
          ["Average Section 1 Time", data[:timing_metrics][:avg_section1_formatted] || "N/A"],
          ["Average Section 2 Time", data[:timing_metrics][:avg_section2_formatted] || "N/A"],
          ["Average Total Time", data[:timing_metrics][:avg_total_formatted] || "N/A"]
        ]

        pdf.table(timing_data, width: pdf.bounds.width / 2) do
          cells.padding = 8
          cells.borders = [:bottom]
        end

        pdf.move_down 20

        # Overdue verifications
        if data[:overdue][:count] > 0
          pdf.text "Overdue Verifications (#{data[:overdue][:count]})", size: 16, style: :bold, color: "CC0000"
          pdf.move_down 10

          overdue_headers = ["Candidate", "Job", "Deadline", "Days Overdue"]
          overdue_rows = data[:overdue][:verifications].map do |v|
            [v[:candidate_name], v[:job_title], v[:deadline].strftime("%Y-%m-%d"), v[:days_overdue]]
          end

          pdf.table([overdue_headers] + overdue_rows, header: true, width: pdf.bounds.width) do
            row(0).font_style = :bold
            row(0).background_color = "EEEEEE"
            cells.padding = 6
          end

          pdf.move_down 20
        end

        # Department breakdown
        pdf.text "By Department", size: 16, style: :bold
        pdf.move_down 10

        dept_headers = ["Department", "Total", "Verified", "Completion Rate"]
        dept_rows = data[:by_department].map do |d|
          [d[:department_name], d[:total], d[:verified], "#{d[:completion_rate]}%"]
        end

        if dept_rows.any?
          pdf.table([dept_headers] + dept_rows, header: true, width: pdf.bounds.width) do
            row(0).font_style = :bold
            row(0).background_color = "EEEEEE"
            cells.padding = 6
          end
        else
          pdf.text "No department data available", color: "666666"
        end
      end
    end
  end
end
