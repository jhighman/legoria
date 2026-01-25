# frozen_string_literal: true

# Job to generate report snapshots on a schedule
# Run daily to pre-compute expensive analytics
class GenerateReportSnapshotJob < ApplicationJob
  queue_as :default

  REPORT_CONFIGS = [
    { report_type: "eeoc", period_type: "monthly" },
    { report_type: "diversity", period_type: "monthly" },
    { report_type: "pipeline", period_type: "weekly" },
    { report_type: "time_to_hire", period_type: "weekly" },
    { report_type: "source_effectiveness", period_type: "weekly" },
    { report_type: "operational", period_type: "daily" }
  ].freeze

  def perform(organization_id: nil, report_type: nil)
    organizations = if organization_id
                      [Organization.find(organization_id)]
                    else
                      Organization.all
                    end

    organizations.each do |org|
      generate_for_organization(org, report_type)
    end
  end

  private

  def generate_for_organization(organization, specific_type = nil)
    Current.organization = organization

    configs = specific_type ? REPORT_CONFIGS.select { |c| c[:report_type] == specific_type } : REPORT_CONFIGS

    configs.each do |config|
      generate_snapshot(config[:report_type], config[:period_type])
    rescue StandardError => e
      Rails.logger.error "Failed to generate #{config[:report_type]} snapshot for #{organization.name}: #{e.message}"
    end
  ensure
    Current.reset
  end

  def generate_snapshot(report_type, period_type)
    period_start, period_end = calculate_period(period_type)

    ReportSnapshot.generate(
      report_type: report_type,
      period_type: period_type,
      period_start: period_start,
      period_end: period_end
    )

    Rails.logger.info "Generated #{report_type} (#{period_type}) snapshot for #{Current.organization.name}"
  end

  def calculate_period(period_type)
    case period_type
    when "daily"
      [Date.current, Date.current]
    when "weekly"
      [Date.current.beginning_of_week, Date.current.end_of_week]
    when "monthly"
      [Date.current.beginning_of_month, Date.current.end_of_month]
    when "quarterly"
      [Date.current.beginning_of_quarter, Date.current.end_of_quarter]
    when "yearly"
      [Date.current.beginning_of_year, Date.current.end_of_year]
    else
      [30.days.ago.to_date, Date.current]
    end
  end
end
