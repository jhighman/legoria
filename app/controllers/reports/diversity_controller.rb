# frozen_string_literal: true

module Reports
  class DiversityController < BaseController
    before_action :authorize_diversity

    def index
      @data = DiversityMetricsQuery.call(**filter_params)
      @jobs = Job.kept.order(:title)
      @departments = Department.order(:name)

      respond_to do |format|
        format.html
        format.json { render json: @data }
      end
    end

    def adverse_impact
      @data = AdverseImpactQuery.call(**filter_params)
      @jobs = Job.kept.order(:title)
      @departments = Department.order(:name)

      respond_to do |format|
        format.html
        format.json { render json: @data }
      end
    end

    def pdf
      authorize :report, :export_diversity_pdf?

      diversity_data = DiversityMetricsQuery.call(**filter_params)
      impact_data = AdverseImpactQuery.call(**filter_params)

      document = generate_pdf(diversity_data, impact_data)
      send_pdf(document, "diversity_report")
    end

    private

    def authorize_diversity
      authorize :report, :diversity?
    end

    def report_title
      "Diversity Metrics"
    end

    def generate_pdf(diversity_data, impact_data)
      require "prawn"
      require "prawn/table"

      Prawn::Document.new do |pdf|
        pdf_header(pdf, "Diversity & Inclusion Report", date_range_label)

        # Diversity Summary
        pdf.text "Diversity Summary", size: 16, style: :bold
        pdf.move_down 10

        if diversity_data[:summary][:note]
          pdf.text diversity_data[:summary][:note], style: :italic, color: "666666"
        else
          summary_data = [
            ["Total Respondents", diversity_data[:summary][:total_respondents]],
            ["Diversity Index", "#{diversity_data[:summary][:diversity_index]} (#{diversity_data[:summary][:diversity_index_label]})"],
            ["Underrepresented Groups", "#{diversity_data[:summary][:underrepresented_percentage]}%"]
          ]
          pdf.table(summary_data, width: pdf.bounds.width / 2)
        end

        pdf.move_down 20

        # Representation
        pdf.text "Representation by Race/Ethnicity", size: 14, style: :bold
        pdf.move_down 10

        race_table = [["Group", "Count", "Percentage"]]
        diversity_data[:representation][:by_race].each do |row|
          next if row[:anonymized]

          race_table << [row[:label], row[:count].to_s, row[:percentage] ? "#{row[:percentage]}%" : "N/A"]
        end
        pdf.table(race_table, header: true, width: pdf.bounds.width) if race_table.size > 1

        pdf.move_down 20

        # Adverse Impact
        pdf.text "Adverse Impact Analysis", size: 16, style: :bold
        pdf.move_down 10

        if impact_data[:summary][:adverse_impact_detected]
          pdf.text "ATTENTION: Potential adverse impact detected", color: "CC0000", style: :bold
          pdf.move_down 10
        else
          pdf.text "No adverse impact detected", color: "008800"
          pdf.move_down 10
        end

        impact_table = [["Group", "Applicants", "Hired", "Selection Rate", "Impact Ratio", "Status"]]
        impact_data[:by_race].each do |row|
          impact_table << [
            row[:label],
            row[:applicants],
            row[:hired],
            "#{row[:selection_rate]}%",
            row[:impact_ratio],
            row[:status]
          ]
        end
        pdf.table(impact_table, header: true, width: pdf.bounds.width) if impact_table.size > 1

        pdf.move_down 20

        # Methodology
        pdf.text "Methodology", size: 12, style: :bold
        pdf.move_down 5
        pdf.text impact_data[:methodology][:description], size: 9, color: "666666"

        pdf.move_down 10
        pdf.text impact_data[:methodology][:disclaimer], size: 8, style: :italic, color: "999999"

        # Footer with branding
        pdf_footer(pdf)
      end
    end
  end
end
