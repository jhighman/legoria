# frozen_string_literal: true

# Query object for source effectiveness analytics
# Tracks applicant volume, conversion rates, and quality by source
class SourceEffectivenessQuery < ApplicationQuery
  option :start_date
  option :end_date
  option :job_id, optional: true
  option :department_id, optional: true

  def call
    {
      summary: summary_metrics,
      by_source: source_breakdown,
      trend: trend_data,
      quality_metrics: quality_by_source
    }
  end

  private

  def base_scope
    scope = Application.kept.where(applied_at: start_date..end_date)
    scope = scope.where(job_id: job_id) if job_id.present?
    scope = scope.joins(:job).where(jobs: { department_id: department_id }) if department_id.present?
    scope
  end

  def summary_metrics
    total = base_scope.count
    sources_count = base_scope.distinct.count(:source_type)
    hired = base_scope.where(status: "hired").count

    {
      total_applications: total,
      unique_sources: sources_count,
      total_hires: hired,
      overall_conversion: percentage(hired, total)
    }
  end

  def source_breakdown
    sources = base_scope.group(:source_type).count

    sources.map do |source, count|
      hired = base_scope.where(source_type: source, status: "hired").count
      in_progress = base_scope.where(source_type: source).active.count
      rejected = base_scope.where(source_type: source, status: "rejected").count

      # Calculate cost per hire if available (placeholder for future)
      {
        source_type: source,
        source_label: source.to_s.titleize,
        applications: count,
        in_progress: in_progress,
        hired: hired,
        rejected: rejected,
        conversion_rate: percentage(hired, count),
        quality_score: calculate_quality_score(source)
      }
    end.sort_by { |s| -s[:applications] }
  end

  def trend_data
    # Weekly trend by source
    sources = base_scope.distinct.pluck(:source_type)

    weeks = []
    current_week = start_date.beginning_of_week

    while current_week <= end_date
      week_end = [current_week.end_of_week, end_date].min

      week_data = {
        week: current_week.to_date,
        label: current_week.strftime("%b %d"),
        sources: {}
      }

      sources.each do |source|
        count = Application.kept
                           .where(source_type: source)
                           .where(applied_at: current_week..week_end)
        count = count.where(job_id: job_id) if job_id.present?
        week_data[:sources][source] = count.count
      end

      weeks << week_data
      current_week += 1.week
    end

    weeks
  end

  def quality_by_source
    sources = base_scope.distinct.pluck(:source_type)

    sources.map do |source|
      apps = base_scope.where(source_type: source)

      avg_rating = apps.where.not(rating: nil).average(:rating)&.round(1)
      avg_time_to_hire = calculate_avg_time_to_hire(source)
      interview_rate = calculate_interview_rate(source)

      {
        source_type: source,
        source_label: source.to_s.titleize,
        average_rating: avg_rating || 0,
        avg_time_to_hire: avg_time_to_hire,
        interview_rate: interview_rate
      }
    end.sort_by { |s| -(s[:average_rating] || 0) }
  end

  def calculate_quality_score(source)
    apps = base_scope.where(source_type: source)

    # Quality score based on:
    # - Conversion rate (40%)
    # - Average rating (30%)
    # - Interview advancement rate (30%)

    hired = apps.where(status: "hired").count
    total = apps.count
    return 0 if total.zero?

    conversion = percentage(hired, total)
    avg_rating = apps.where.not(rating: nil).average(:rating)&.to_f || 3.0
    interview_rate = calculate_interview_rate(source)

    score = (conversion * 0.4) + (avg_rating * 20 * 0.3) + (interview_rate * 0.3)
    score.round(1)
  end

  def calculate_avg_time_to_hire(source)
    hired_apps = base_scope.where(source_type: source, status: "hired")
    return nil unless hired_apps.exists?

    days = hired_apps.pluck(:applied_at, :hired_at).map do |applied, hired|
      (hired.to_date - applied.to_date).to_i
    end

    days.any? ? (days.sum.to_f / days.size).round(1) : nil
  end

  def calculate_interview_rate(source)
    apps = base_scope.where(source_type: source)
    total = apps.count
    return 0 if total.zero?

    # Applications that reached interview stage or beyond
    interviewed = apps.where(status: %w[interviewing assessment background_check offered hired]).count
    percentage(interviewed, total)
  end
end
