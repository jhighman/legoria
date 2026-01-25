# frozen_string_literal: true

# Query object for diversity metrics with anonymization
# Provides high-level diversity analytics while protecting individual privacy
class DiversityMetricsQuery < ApplicationQuery
  option :start_date
  option :end_date
  option :job_id, optional: true
  option :department_id, optional: true

  ANONYMIZATION_THRESHOLD = 5

  def call
    {
      summary: diversity_summary,
      representation: representation_metrics,
      hiring_diversity: hiring_diversity_metrics,
      stage_progression: stage_progression_by_group,
      trends: diversity_trends
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

  def diversity_summary
    total = base_scope.count
    return empty_summary if total < ANONYMIZATION_THRESHOLD

    # Calculate diversity index (Simpson's Diversity Index for race/ethnicity)
    race_counts = base_scope.group(:race_ethnicity).count
    diversity_index = calculate_diversity_index(race_counts, total)

    # Gender ratio
    gender_counts = base_scope.group(:gender).count
    female_count = gender_counts["female"] || 0
    male_count = gender_counts["male"] || 0

    {
      total_respondents: total,
      diversity_index: diversity_index.round(2),
      diversity_index_label: diversity_index_label(diversity_index),
      gender_ratio: {
        female: percentage(female_count, female_count + male_count),
        male: percentage(male_count, female_count + male_count)
      },
      underrepresented_percentage: calculate_underrepresented_percentage
    }
  end

  def representation_metrics
    {
      by_gender: calculate_representation(:gender, EeocResponse::GENDERS),
      by_race: calculate_representation(:race_ethnicity, EeocResponse::RACE_ETHNICITIES),
      by_veteran: calculate_representation(:veteran_status, EeocResponse::VETERAN_STATUSES),
      by_disability: calculate_representation(:disability_status, EeocResponse::DISABILITY_STATUSES)
    }
  end

  def calculate_representation(field, values)
    counts = base_scope.group(field).count
    total = counts.values.sum

    values.map do |value|
      count = counts[value] || 0
      anonymized = count < ANONYMIZATION_THRESHOLD

      {
        value: value,
        label: format_label(field, value),
        count: anonymized ? "< #{ANONYMIZATION_THRESHOLD}" : count,
        percentage: anonymized ? nil : percentage(count, total),
        anonymized: anonymized
      }
    end
  end

  def hiring_diversity_metrics
    hired_scope = base_scope.joins(:application).where(applications: { status: "hired" })
    total_hired = hired_scope.count

    return { total: 0, note: "Insufficient data" } if total_hired < ANONYMIZATION_THRESHOLD

    {
      total_hired: total_hired,
      by_gender: calculate_hired_breakdown(:gender, EeocResponse::GENDERS, hired_scope),
      by_race: calculate_hired_breakdown(:race_ethnicity, EeocResponse::RACE_ETHNICITIES, hired_scope),
      comparison_to_applicants: compare_hired_to_applicants
    }
  end

  def calculate_hired_breakdown(field, values, scope)
    counts = scope.group(field).count
    total = counts.values.sum

    values.map do |value|
      count = counts[value] || 0
      anonymized = count < ANONYMIZATION_THRESHOLD

      {
        value: value,
        label: format_label(field, value),
        hired: anonymized ? "< #{ANONYMIZATION_THRESHOLD}" : count,
        percentage: anonymized ? nil : percentage(count, total)
      }
    end.reject { |v| v[:hired] == 0 || v[:hired] == "< #{ANONYMIZATION_THRESHOLD}" }
  end

  def stage_progression_by_group
    # Track how different groups progress through stages
    stages = Stage.where(is_default: true, is_terminal: false).order(:position)

    stages.map do |stage|
      stage_apps = Application.kept
                              .where(applied_at: start_date..end_date)
                              .joins(:stage_transitions)
                              .where(stage_transitions: { to_stage_id: stage.id })
                              .joins(:eeoc_response)
                              .where(eeoc_responses: { consent_given: true })

      total = stage_apps.count
      next if total < ANONYMIZATION_THRESHOLD

      race_counts = EeocResponse.where(application_id: stage_apps.select(:id))
                                .group(:race_ethnicity)
                                .count

      {
        stage_id: stage.id,
        stage_name: stage.name,
        total: total,
        by_race: race_counts.transform_values { |v| v < ANONYMIZATION_THRESHOLD ? "< #{ANONYMIZATION_THRESHOLD}" : v }
      }
    end.compact
  end

  def diversity_trends
    # Monthly diversity index trend
    months = []
    current_month = start_date.beginning_of_month

    while current_month <= end_date
      month_end = current_month.end_of_month

      month_scope = EeocResponse.with_consent
                                .joins(:application)
                                .where(applications: { applied_at: current_month..month_end })

      total = month_scope.count
      if total >= ANONYMIZATION_THRESHOLD
        race_counts = month_scope.group(:race_ethnicity).count
        diversity_index = calculate_diversity_index(race_counts, total)

        months << {
          month: current_month.to_date,
          label: current_month.strftime("%b %Y"),
          diversity_index: diversity_index.round(2),
          total_respondents: total
        }
      end

      current_month += 1.month
    end

    months
  end

  def compare_hired_to_applicants
    # Compare demographic distribution of hires vs applicants
    applicant_counts = base_scope.group(:race_ethnicity).count
    hired_counts = base_scope.joins(:application)
                             .where(applications: { status: "hired" })
                             .group(:race_ethnicity)
                             .count

    applicant_total = applicant_counts.values.sum
    hired_total = hired_counts.values.sum

    return [] if hired_total < ANONYMIZATION_THRESHOLD

    EeocResponse::RACE_ETHNICITIES.map do |race|
      app_count = applicant_counts[race] || 0
      hire_count = hired_counts[race] || 0

      next if app_count < ANONYMIZATION_THRESHOLD

      app_pct = percentage(app_count, applicant_total)
      hire_pct = percentage(hire_count, hired_total)

      {
        race: race,
        label: format_label(:race_ethnicity, race),
        applicant_percentage: app_pct,
        hire_percentage: hire_pct,
        difference: (hire_pct - app_pct).round(1)
      }
    end.compact
  end

  # Simpson's Diversity Index: 1 - sum((n/N)^2)
  # Ranges from 0 (no diversity) to 1 (maximum diversity)
  def calculate_diversity_index(counts, total)
    return 0.0 if total.zero?

    sum_of_squares = counts.values.sum { |n| (n.to_f / total) ** 2 }
    1.0 - sum_of_squares
  end

  def diversity_index_label(index)
    case index
    when 0...0.3 then "Low"
    when 0.3...0.6 then "Moderate"
    when 0.6...0.8 then "Good"
    else "Excellent"
    end
  end

  def calculate_underrepresented_percentage
    # Groups traditionally underrepresented in tech/corporate
    underrepresented = %w[hispanic_latino black native_american pacific_islander two_or_more]

    total = base_scope.count
    return 0 if total < ANONYMIZATION_THRESHOLD

    count = base_scope.where(race_ethnicity: underrepresented).count
    percentage(count, total)
  end

  def format_label(field, value)
    case field
    when :gender
      value.titleize.gsub("_", " ")
    when :race_ethnicity
      case value
      when "hispanic_latino" then "Hispanic/Latino"
      when "black" then "Black/African American"
      when "asian" then "Asian"
      when "white" then "White"
      when "native_american" then "Native American"
      when "pacific_islander" then "Pacific Islander"
      when "two_or_more" then "Two or More Races"
      else value.titleize
      end
    else
      value.titleize.gsub("_", " ")
    end
  end

  def empty_summary
    {
      total_respondents: 0,
      diversity_index: 0,
      diversity_index_label: "Insufficient data",
      gender_ratio: { female: 0, male: 0 },
      underrepresented_percentage: 0,
      note: "Fewer than #{ANONYMIZATION_THRESHOLD} responses - data anonymized"
    }
  end
end
