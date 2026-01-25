# frozen_string_literal: true

# Query object for EEOC compliance reporting
# Generates EEO-1 style demographic data with proper anonymization
class EeocReportQuery < ApplicationQuery
  option :start_date
  option :end_date
  option :job_id, optional: true
  option :department_id, optional: true

  # Minimum group size for reporting (to protect privacy)
  ANONYMIZATION_THRESHOLD = 5

  def call
    {
      summary: summary_metrics,
      by_gender: gender_breakdown,
      by_race_ethnicity: race_ethnicity_breakdown,
      by_veteran_status: veteran_breakdown,
      by_disability_status: disability_breakdown,
      by_job_category: job_category_breakdown,
      collection_rates: collection_rate_metrics,
      trend: historical_trend
    }
  end

  private

  def base_scope
    scope = EeocResponse.with_consent
                        .joins(:application)
                        .where(applications: { applied_at: start_date..end_date })

    scope = scope.where(applications: { job_id: job_id }) if job_id.present?
    if department_id.present?
      scope = scope.joins(application: :job).where(jobs: { department_id: department_id })
    end
    scope
  end

  def applications_scope
    scope = Application.kept.where(applied_at: start_date..end_date)
    scope = scope.where(job_id: job_id) if job_id.present?
    scope = scope.joins(:job).where(jobs: { department_id: department_id }) if department_id.present?
    scope
  end

  def summary_metrics
    total_applications = applications_scope.count
    total_responses = base_scope.count
    hired_count = applications_scope.where(status: "hired").count

    {
      total_applications: total_applications,
      eeoc_responses: total_responses,
      response_rate: percentage(total_responses, total_applications),
      hired: hired_count,
      date_range: "#{start_date.strftime('%b %d, %Y')} - #{end_date.strftime('%b %d, %Y')}"
    }
  end

  def gender_breakdown
    counts = base_scope.group(:gender).count
    total = counts.values.sum

    EeocResponse::GENDERS.map do |gender|
      count = counts[gender] || 0

      {
        value: gender,
        label: gender.titleize.gsub("_", " "),
        count: anonymize_count(count),
        percentage: percentage(count, total),
        hired: anonymize_count(hired_count_for(:gender, gender))
      }
    end
  end

  def race_ethnicity_breakdown
    counts = base_scope.group(:race_ethnicity).count
    total = counts.values.sum

    EeocResponse::RACE_ETHNICITIES.map do |race|
      count = counts[race] || 0
      hired = hired_count_for(:race_ethnicity, race)

      {
        value: race,
        label: race_label(race),
        count: anonymize_count(count),
        percentage: percentage(count, total),
        hired: anonymize_count(hired),
        selection_rate: calculate_selection_rate(count, hired)
      }
    end
  end

  def veteran_breakdown
    counts = base_scope.group(:veteran_status).count
    total = counts.values.sum

    EeocResponse::VETERAN_STATUSES.map do |status|
      count = counts[status] || 0

      {
        value: status,
        label: status.titleize.gsub("_", " "),
        count: anonymize_count(count),
        percentage: percentage(count, total),
        hired: anonymize_count(hired_count_for(:veteran_status, status))
      }
    end
  end

  def disability_breakdown
    counts = base_scope.group(:disability_status).count
    total = counts.values.sum

    EeocResponse::DISABILITY_STATUSES.map do |status|
      count = counts[status] || 0

      {
        value: status,
        label: disability_label(status),
        count: anonymize_count(count),
        percentage: percentage(count, total),
        hired: anonymize_count(hired_count_for(:disability_status, status))
      }
    end
  end

  def job_category_breakdown
    # Group by department as proxy for job category
    Department.order(:name).map do |dept|
      dept_scope = base_scope.joins(application: :job).where(jobs: { department_id: dept.id })
      total = dept_scope.count

      next if total.zero?

      gender_counts = dept_scope.group(:gender).count
      race_counts = dept_scope.group(:race_ethnicity).count

      {
        department_id: dept.id,
        department_name: dept.name,
        total: anonymize_count(total),
        gender_breakdown: gender_counts.transform_values { |v| anonymize_count(v) },
        race_breakdown: race_counts.transform_values { |v| anonymize_count(v) }
      }
    end.compact
  end

  def collection_rate_metrics
    # Track EEOC collection effectiveness by context
    total_apps = applications_scope.count
    responses = base_scope.count

    by_context = EeocResponse::COLLECTION_CONTEXTS.map do |context|
      count = base_scope.where(collection_context: context).count
      {
        context: context,
        label: context.titleize.gsub("_", " "),
        count: count,
        percentage: percentage(count, responses)
      }
    end

    {
      overall_rate: percentage(responses, total_apps),
      by_context: by_context,
      decline_rate: calculate_decline_rate
    }
  end

  def historical_trend
    # Monthly trend data
    months = []
    current_month = start_date.beginning_of_month

    while current_month <= end_date
      month_end = current_month.end_of_month

      month_responses = EeocResponse.with_consent
                                    .joins(:application)
                                    .where(applications: { applied_at: current_month..month_end })
                                    .count

      month_apps = Application.kept.where(applied_at: current_month..month_end).count

      months << {
        month: current_month.to_date,
        label: current_month.strftime("%b %Y"),
        responses: month_responses,
        applications: month_apps,
        response_rate: percentage(month_responses, month_apps)
      }

      current_month += 1.month
    end

    months
  end

  # Anonymization helper - shows "< 5" for small groups
  def anonymize_count(count)
    count < ANONYMIZATION_THRESHOLD ? "< #{ANONYMIZATION_THRESHOLD}" : count
  end

  def hired_count_for(field, value)
    base_scope.joins(:application)
              .where(field => value)
              .where(applications: { status: "hired" })
              .count
  end

  def calculate_selection_rate(applicants, hired)
    return 0 if applicants < ANONYMIZATION_THRESHOLD
    return 0 if applicants.zero?

    hired_count = hired.is_a?(String) ? 0 : hired
    percentage(hired_count, applicants)
  end

  def calculate_decline_rate
    all_declined = base_scope.select(&:all_declined?).count
    total = base_scope.count
    percentage(all_declined, total)
  end

  def race_label(race)
    case race
    when "hispanic_latino" then "Hispanic or Latino"
    when "white" then "White"
    when "black" then "Black or African American"
    when "asian" then "Asian"
    when "native_american" then "American Indian or Alaska Native"
    when "pacific_islander" then "Native Hawaiian or Pacific Islander"
    when "two_or_more" then "Two or More Races"
    when "prefer_not_to_say" then "Prefer not to say"
    else race.titleize
    end
  end

  def disability_label(status)
    case status
    when "yes" then "Has a disability"
    when "no" then "No disability"
    when "prefer_not_to_say" then "Prefer not to say"
    else status.titleize
    end
  end
end
