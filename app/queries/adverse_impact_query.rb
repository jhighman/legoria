# frozen_string_literal: true

# Query object for adverse impact analysis using the 4/5ths rule
# EEOC guidelines state that a selection rate for any group less than
# 80% of the rate for the group with the highest rate is adverse impact
class AdverseImpactQuery < ApplicationQuery
  option :start_date
  option :end_date
  option :job_id, optional: true
  option :department_id, optional: true

  ADVERSE_IMPACT_THRESHOLD = 0.80
  ANONYMIZATION_THRESHOLD = 5

  def call
    {
      summary: impact_summary,
      by_race: race_impact_analysis,
      by_gender: gender_impact_analysis,
      by_stage: stage_by_stage_analysis,
      recommendations: generate_recommendations,
      methodology: methodology_note
    }
  end

  private

  def base_scope
    scope = Application.kept.where(applied_at: start_date..end_date)
    scope = scope.where(job_id: job_id) if job_id.present?
    scope = scope.joins(:job).where(jobs: { department_id: department_id }) if department_id.present?
    scope
  end

  def eeoc_scope
    scope = EeocResponse.with_consent
                        .joins(:application)
                        .where(applications: { applied_at: start_date..end_date })

    scope = scope.where(applications: { job_id: job_id }) if job_id.present?
    if department_id.present?
      scope = scope.joins(application: :job).where(jobs: { department_id: department_id })
    end
    scope
  end

  def impact_summary
    race_analysis = race_impact_analysis
    gender_analysis = gender_impact_analysis

    race_issues = race_analysis.count { |r| r[:has_adverse_impact] }
    gender_issues = gender_analysis.count { |r| r[:has_adverse_impact] }

    {
      total_applications: base_scope.count,
      total_hires: base_scope.where(status: "hired").count,
      eeoc_responses: eeoc_scope.count,
      adverse_impact_detected: race_issues.positive? || gender_issues.positive?,
      race_groups_with_impact: race_issues,
      gender_groups_with_impact: gender_issues,
      analysis_period: "#{start_date.strftime('%b %d, %Y')} - #{end_date.strftime('%b %d, %Y')}"
    }
  end

  def race_impact_analysis
    groups = EeocResponse::RACE_ETHNICITIES.reject { |r| r == "prefer_not_to_say" }

    rates = groups.map do |race|
      applicants = eeoc_scope.where(race_ethnicity: race).count
      next if applicants < ANONYMIZATION_THRESHOLD

      hired = eeoc_scope.joins(:application)
                        .where(race_ethnicity: race)
                        .where(applications: { status: "hired" })
                        .count

      selection_rate = applicants.positive? ? (hired.to_f / applicants) : 0

      {
        group: race,
        label: race_label(race),
        applicants: applicants,
        hired: hired,
        selection_rate: (selection_rate * 100).round(1)
      }
    end.compact

    return [] if rates.empty?

    highest_rate = rates.map { |r| r[:selection_rate] }.max

    rates.map do |rate|
      impact_ratio = highest_rate.positive? ? (rate[:selection_rate] / highest_rate) : 1.0
      has_adverse_impact = impact_ratio < ADVERSE_IMPACT_THRESHOLD && rate[:selection_rate] < highest_rate

      rate.merge(
        impact_ratio: impact_ratio.round(2),
        has_adverse_impact: has_adverse_impact,
        status: impact_status(impact_ratio, has_adverse_impact),
        status_color: impact_color(impact_ratio, has_adverse_impact)
      )
    end.sort_by { |r| r[:impact_ratio] }
  end

  def gender_impact_analysis
    groups = %w[male female non_binary]

    rates = groups.map do |gender|
      applicants = eeoc_scope.where(gender: gender).count
      next if applicants < ANONYMIZATION_THRESHOLD

      hired = eeoc_scope.joins(:application)
                        .where(gender: gender)
                        .where(applications: { status: "hired" })
                        .count

      selection_rate = applicants.positive? ? (hired.to_f / applicants) : 0

      {
        group: gender,
        label: gender.titleize.gsub("_", " "),
        applicants: applicants,
        hired: hired,
        selection_rate: (selection_rate * 100).round(1)
      }
    end.compact

    return [] if rates.empty?

    highest_rate = rates.map { |r| r[:selection_rate] }.max

    rates.map do |rate|
      impact_ratio = highest_rate.positive? ? (rate[:selection_rate] / highest_rate) : 1.0
      has_adverse_impact = impact_ratio < ADVERSE_IMPACT_THRESHOLD && rate[:selection_rate] < highest_rate

      rate.merge(
        impact_ratio: impact_ratio.round(2),
        has_adverse_impact: has_adverse_impact,
        status: impact_status(impact_ratio, has_adverse_impact),
        status_color: impact_color(impact_ratio, has_adverse_impact)
      )
    end.sort_by { |r| r[:impact_ratio] }
  end

  def stage_by_stage_analysis
    stages = Stage.where(is_default: true).order(:position)

    stages.map do |stage|
      # Get applications that reached this stage
      stage_apps = base_scope.joins(:stage_transitions)
                             .where(stage_transitions: { to_stage_id: stage.id })
                             .joins(:eeoc_response)
                             .where(eeoc_responses: { consent_given: true })
                             .distinct

      total = stage_apps.count
      next if total < ANONYMIZATION_THRESHOLD * 2

      # Group by race
      race_counts = EeocResponse.where(application_id: stage_apps.pluck(:id))
                                .group(:race_ethnicity)
                                .count

      # Find if any group is underrepresented at this stage
      max_count = race_counts.values.max || 0

      issues = race_counts.select do |race, count|
        next false if count < ANONYMIZATION_THRESHOLD
        next false if race == "prefer_not_to_say"

        ratio = max_count.positive? ? (count.to_f / max_count) : 1.0
        ratio < ADVERSE_IMPACT_THRESHOLD
      end

      {
        stage_id: stage.id,
        stage_name: stage.name,
        total_reached: total,
        potential_issues: issues.keys.map { |r| race_label(r) },
        has_issues: issues.any?
      }
    end.compact
  end

  def generate_recommendations
    recommendations = []

    race_analysis = race_impact_analysis
    gender_analysis = gender_impact_analysis

    race_issues = race_analysis.select { |r| r[:has_adverse_impact] }
    gender_issues = gender_analysis.select { |r| r[:has_adverse_impact] }

    if race_issues.any?
      race_issues.each do |issue|
        recommendations << {
          priority: "high",
          category: "race_ethnicity",
          group: issue[:label],
          impact_ratio: issue[:impact_ratio],
          recommendation: "Review selection criteria for potential barriers affecting #{issue[:label]} candidates",
          action_items: [
            "Audit screening criteria for unintended bias",
            "Review interview scoring consistency",
            "Consider blind resume review practices"
          ]
        }
      end
    end

    if gender_issues.any?
      gender_issues.each do |issue|
        recommendations << {
          priority: "high",
          category: "gender",
          group: issue[:label],
          impact_ratio: issue[:impact_ratio],
          recommendation: "Investigate selection rate disparity for #{issue[:label]} candidates",
          action_items: [
            "Review job descriptions for gendered language",
            "Ensure diverse interview panels",
            "Audit compensation offers for equity"
          ]
        }
      end
    end

    if recommendations.empty?
      recommendations << {
        priority: "info",
        category: "general",
        group: nil,
        recommendation: "No adverse impact detected in current selection rates",
        action_items: ["Continue monitoring diversity metrics", "Maintain inclusive hiring practices"]
      }
    end

    recommendations
  end

  def methodology_note
    {
      rule: "4/5ths (80%) Rule",
      description: "The EEOC uses the 4/5ths rule to identify potential adverse impact. " \
                   "A selection rate for any group that is less than 80% of the rate for " \
                   "the group with the highest rate is considered evidence of adverse impact.",
      threshold: "#{(ADVERSE_IMPACT_THRESHOLD * 100).to_i}%",
      anonymization: "Groups with fewer than #{ANONYMIZATION_THRESHOLD} members are excluded to protect privacy",
      disclaimer: "This analysis is for informational purposes only and does not constitute legal advice. " \
                  "Consult with legal counsel for compliance guidance."
    }
  end

  def impact_status(ratio, has_impact)
    if has_impact
      "Adverse Impact Detected"
    elsif ratio >= 0.9
      "No Concern"
    else
      "Monitor"
    end
  end

  def impact_color(ratio, has_impact)
    if has_impact
      "danger"
    elsif ratio >= 0.9
      "success"
    else
      "warning"
    end
  end

  def race_label(race)
    case race
    when "hispanic_latino" then "Hispanic/Latino"
    when "black" then "Black/African American"
    when "asian" then "Asian"
    when "white" then "White"
    when "native_american" then "Native American"
    when "pacific_islander" then "Pacific Islander"
    when "two_or_more" then "Two or More Races"
    else race.titleize
    end
  end
end
