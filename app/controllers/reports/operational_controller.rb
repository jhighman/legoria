# frozen_string_literal: true

module Reports
  class OperationalController < BaseController
    before_action :authorize_operational

    def index
      @productivity = RecruiterProductivityQuery.call(start_date: start_date, end_date: end_date)
      @aging = RequisitionAgingQuery.call(**filter_params.except(:job_id, :source_type))
      @departments = Department.order(:name)
    end

    def recruiter_productivity
      @data = RecruiterProductivityQuery.call(start_date: start_date, end_date: end_date)

      respond_to do |format|
        format.html
        format.json { render json: chart_data(:productivity) }
      end
    end

    def requisition_aging
      @data = RequisitionAgingQuery.call(**filter_params.except(:job_id, :source_type))
      @departments = Department.order(:name)

      respond_to do |format|
        format.html
        format.json { render json: chart_data(:aging) }
      end
    end

    def export
      authorize :report, :export?

      type = params[:type] || "productivity"
      data = case type
             when "productivity"
               RecruiterProductivityQuery.call(start_date: start_date, end_date: end_date)
             when "aging"
               RequisitionAgingQuery.call(**filter_params.except(:job_id, :source_type))
             end

      csv = generate_csv(type, data)
      send_csv(csv, "#{type}_report")
    end

    private

    def authorize_operational
      authorize :report, :operational?
    end

    def report_title
      "Operational Dashboard"
    end

    def chart_data(type)
      case type
      when :productivity
        {
          labels: @data[:by_recruiter].map { |r| r[:recruiter_name] },
          datasets: [{
            label: "Hires",
            data: @data[:by_recruiter].map { |r| r[:hires] },
            backgroundColor: "#10B981"
          }, {
            label: "Interviews",
            data: @data[:by_recruiter].map { |r| r[:interviews_scheduled] },
            backgroundColor: "#3B82F6"
          }]
        }
      when :aging
        {
          labels: @data[:aging_breakdown].map { |b| b[:label] },
          datasets: [{
            label: "Open Jobs",
            data: @data[:aging_breakdown].map { |b| b[:count] },
            backgroundColor: ["#10B981", "#3B82F6", "#F59E0B", "#EF4444", "#7C3AED"]
          }]
        }
      end
    end

    def generate_csv(type, data)
      require "csv"

      case type
      when "productivity"
        CSV.generate(headers: true) do |csv|
          csv << ["Recruiter", "Active Jobs", "Applications", "Stage Moves", "Interviews", "Offers", "Hires", "Conversion Rate"]
          data[:by_recruiter].each do |row|
            csv << [
              row[:recruiter_name], row[:active_jobs], row[:applications_received],
              row[:stage_moves], row[:interviews_scheduled], row[:offers_made],
              row[:hires], "#{row[:conversion_rate]}%"
            ]
          end
        end
      when "aging"
        CSV.generate(headers: true) do |csv|
          csv << ["Department", "Open Jobs", "Avg Days Open", "Filled in Period", "Total Applicants"]
          data[:by_department].each do |row|
            csv << [
              row[:department_name], row[:open_jobs], row[:avg_days_open],
              row[:filled_in_period], row[:total_applicants]
            ]
          end
        end
      end
    end
  end
end
