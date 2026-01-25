# frozen_string_literal: true

# Query object for time-to-hire analytics
# Calculates average days from applied_at to hired_at
class TimeToHireQuery < ApplicationQuery
  option :start_date
  option :end_date
  option :job_id, optional: true
  option :department_id, optional: true
  option :source_type, optional: true

  def call
    {
      overall: overall_metrics,
      by_job: metrics_by_job,
      by_department: metrics_by_department,
      by_source: metrics_by_source,
      trend: trend_data,
      raw_data: raw_applications
    }
  end

  private

  def base_scope
    scope = Application.kept
                       .where(status: "hired")
                       .where(hired_at: start_date..end_date)

    scope = scope.where(job_id: job_id) if job_id.present?
    scope = scope.joins(:job).where(jobs: { department_id: department_id }) if department_id.present?
    scope = scope.where(source_type: source_type) if source_type.present?

    scope
  end

  def overall_metrics
    applications = base_scope

    hired_count = applications.count
    return empty_metrics if hired_count.zero?

    # SQLite compatible calculation
    days_data = applications.pluck(:applied_at, :hired_at).map do |applied, hired|
      (hired.to_date - applied.to_date).to_i
    end

    avg_days = days_data.sum.to_f / days_data.size
    min_days = days_data.min
    max_days = days_data.max
    median_days = calculate_median(days_data)

    {
      total_hires: hired_count,
      average_days: avg_days.round(1),
      median_days: median_days,
      min_days: min_days,
      max_days: max_days
    }
  end

  def metrics_by_job
    jobs_data = base_scope
      .joins(:job)
      .group("jobs.id", "jobs.title")
      .pluck("jobs.id", "jobs.title", Arel.sql("COUNT(*)"))

    jobs_data.map do |job_id, title, count|
      days = Application.kept
                        .where(status: "hired", job_id: job_id)
                        .where(hired_at: start_date..end_date)
                        .pluck(:applied_at, :hired_at)
                        .map { |a, h| (h.to_date - a.to_date).to_i }

      avg = days.any? ? (days.sum.to_f / days.size).round(1) : 0

      {
        job_id: job_id,
        job_title: title,
        hires: count,
        average_days: avg
      }
    end.sort_by { |j| -j[:hires] }
  end

  def metrics_by_department
    dept_data = base_scope
      .joins(job: :department)
      .group("departments.id", "departments.name")
      .pluck("departments.id", "departments.name", Arel.sql("COUNT(*)"))

    dept_data.map do |dept_id, name, count|
      days = Application.kept
                        .joins(:job)
                        .where(status: "hired")
                        .where(jobs: { department_id: dept_id })
                        .where(hired_at: start_date..end_date)
                        .pluck(:applied_at, :hired_at)
                        .map { |a, h| (h.to_date - a.to_date).to_i }

      avg = days.any? ? (days.sum.to_f / days.size).round(1) : 0

      {
        department_id: dept_id,
        department_name: name,
        hires: count,
        average_days: avg
      }
    end.sort_by { |d| -d[:hires] }
  end

  def metrics_by_source
    source_data = base_scope
      .group(:source_type)
      .pluck(:source_type, Arel.sql("COUNT(*)"))

    source_data.map do |source, count|
      days = Application.kept
                        .where(status: "hired", source_type: source)
                        .where(hired_at: start_date..end_date)
                        .pluck(:applied_at, :hired_at)
                        .map { |a, h| (h.to_date - a.to_date).to_i }

      avg = days.any? ? (days.sum.to_f / days.size).round(1) : 0

      {
        source_type: source,
        source_label: source.titleize,
        hires: count,
        average_days: avg
      }
    end.sort_by { |s| -s[:hires] }
  end

  def trend_data
    # Group by week for trend visualization
    grouped = base_scope
      .group_by { |app| app.hired_at.beginning_of_week.to_date }

    grouped.map do |week, apps|
      days = apps.map { |a| (a.hired_at.to_date - a.applied_at.to_date).to_i }
      avg = days.any? ? (days.sum.to_f / days.size).round(1) : 0

      {
        week: week,
        label: week.strftime("%b %d"),
        hires: apps.size,
        average_days: avg
      }
    end.sort_by { |t| t[:week] }
  end

  def raw_applications
    base_scope
      .includes(:job, :candidate)
      .order(hired_at: :desc)
      .limit(100)
      .map do |app|
        {
          id: app.id,
          candidate_name: app.candidate.full_name,
          job_title: app.job.title,
          source: app.source_type,
          applied_at: app.applied_at,
          hired_at: app.hired_at,
          days_to_hire: (app.hired_at.to_date - app.applied_at.to_date).to_i
        }
      end
  end

  def empty_metrics
    {
      total_hires: 0,
      average_days: 0,
      median_days: 0,
      min_days: 0,
      max_days: 0
    }
  end

  def calculate_median(array)
    return 0 if array.empty?

    sorted = array.sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end
end
