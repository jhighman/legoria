# frozen_string_literal: true

module Reports
  class EeocController < BaseController
    before_action :authorize_eeoc

    def index
      @data = EeocReportQuery.call(**filter_params)
      @jobs = Job.kept.order(:title)
      @departments = Department.order(:name)
      @historical = ReportSnapshot.historical_trend(report_type: "eeoc", period_type: "monthly", count: 6)

      respond_to do |format|
        format.html
        format.json { render json: @data }
      end
    end

    def export
      authorize :report, :export?

      data = EeocReportQuery.call(**filter_params)
      csv = generate_csv(data)
      send_csv(csv, "eeoc_report")
    end

    def pdf
      authorize :report, :export_diversity_pdf?

      data = EeocReportQuery.call(**filter_params)
      document = generate_pdf(data)
      send_pdf(document, "eeoc_report")
    end

    private

    def authorize_eeoc
      authorize :report, :eeoc?
    end

    def report_title
      "EEOC Compliance Report"
    end

    def generate_csv(data)
      require "csv"

      CSV.generate(headers: true) do |csv|
        csv << ["Category", "Value", "Count", "Percentage", "Hired"]

        csv << []
        csv << ["Gender Breakdown"]
        data[:by_gender].each do |row|
          csv << ["Gender", row[:label], row[:count], "#{row[:percentage]}%", row[:hired]]
        end

        csv << []
        csv << ["Race/Ethnicity Breakdown"]
        data[:by_race_ethnicity].each do |row|
          csv << ["Race/Ethnicity", row[:label], row[:count], "#{row[:percentage]}%", row[:hired]]
        end

        csv << []
        csv << ["Veteran Status"]
        data[:by_veteran_status].each do |row|
          csv << ["Veteran", row[:label], row[:count], "#{row[:percentage]}%", row[:hired]]
        end

        csv << []
        csv << ["Disability Status"]
        data[:by_disability_status].each do |row|
          csv << ["Disability", row[:label], row[:count], "#{row[:percentage]}%", row[:hired]]
        end
      end
    end

    def generate_pdf(data)
      require "prawn"
      require "prawn/table"

      Prawn::Document.new do |pdf|
        pdf_header(pdf, "EEOC Compliance Report", date_range_label)

        # Summary
        pdf.text "Summary", size: 16, style: :bold
        pdf.move_down 10

        summary_data = [
          ["Total Applications", data[:summary][:total_applications]],
          ["EEOC Responses", data[:summary][:eeoc_responses]],
          ["Response Rate", "#{data[:summary][:response_rate]}%"],
          ["Hired", data[:summary][:hired]]
        ]
        pdf.table(summary_data, width: pdf.bounds.width / 2)

        pdf.move_down 20

        # Gender
        pdf.text "Gender Distribution", size: 14, style: :bold
        pdf.move_down 10
        gender_table = [["Gender", "Count", "Percentage", "Hired"]]
        data[:by_gender].each do |row|
          gender_table << [row[:label], row[:count].to_s, "#{row[:percentage]}%", row[:hired].to_s]
        end
        pdf.table(gender_table, header: true, width: pdf.bounds.width)

        pdf.move_down 20

        # Race/Ethnicity
        pdf.text "Race/Ethnicity Distribution", size: 14, style: :bold
        pdf.move_down 10
        race_table = [["Race/Ethnicity", "Count", "Percentage", "Hired"]]
        data[:by_race_ethnicity].each do |row|
          race_table << [row[:label], row[:count].to_s, "#{row[:percentage]}%", row[:hired].to_s]
        end
        pdf.table(race_table, header: true, width: pdf.bounds.width)

        # Footer with branding
        pdf_footer(pdf)
      end
    end
  end
end
