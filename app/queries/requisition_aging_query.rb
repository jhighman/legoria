# frozen_string_literal: true

# Query object for requisition aging analytics
# Tracks how long jobs have been open and time-to-fill metrics
class RequisitionAgingQuery < ApplicationQuery
  option :start_date
  option :end_date
  option :department_id, optional: true

  def call
    {
      summary: summary_metrics,
      aging_breakdown: aging_breakdown,
      by_department: metrics_by_department,
      overdue_jobs: overdue_requisitions,
      fill_rate_trend: fill_rate_trend
    }
  end

  private

  def base_scope
    scope = Job.kept
    scope = scope.where(department_id: department_id) if department_id.present?
    scope
  end

  def open_jobs
    base_scope.open_jobs
  end

  def summary_metrics
    total_open = open_jobs.count
    avg_days_open = calculate_avg_days_open
    filled_in_period = base_scope.where(status: "closed")
                                  .where(closed_at: start_date..end_date)
                                  .where.not(filled_count: 0)
                                  .count

    target_fill_days = 45 # Default target
    on_target = open_jobs.select { |j| days_open(j) <= target_fill_days }.count

    {
      total_open_jobs: total_open,
      avg_days_open: avg_days_open,
      jobs_filled: filled_in_period,
      on_target_count: on_target,
      on_target_percentage: percentage(on_target, total_open)
    }
  end

  def aging_breakdown
    buckets = {
      "0-14 days" => { min: 0, max: 14, count: 0, jobs: [] },
      "15-30 days" => { min: 15, max: 30, count: 0, jobs: [] },
      "31-60 days" => { min: 31, max: 60, count: 0, jobs: [] },
      "61-90 days" => { min: 61, max: 90, count: 0, jobs: [] },
      "90+ days" => { min: 91, max: Float::INFINITY, count: 0, jobs: [] }
    }

    open_jobs.each do |job|
      days = days_open(job)

      buckets.each do |label, bucket|
        if days >= bucket[:min] && days <= bucket[:max]
          bucket[:count] += 1
          bucket[:jobs] << {
            id: job.id,
            title: job.title,
            department: job.department&.name,
            days_open: days,
            applicants: job.applications.kept.count
          }
          break
        end
      end
    end

    buckets.map do |label, data|
      {
        label: label,
        count: data[:count],
        percentage: percentage(data[:count], open_jobs.count),
        jobs: data[:jobs].sort_by { |j| -j[:days_open] }.first(5)
      }
    end
  end

  def metrics_by_department
    Department.order(:name).map do |dept|
      dept_jobs = open_jobs.where(department: dept)
      filled_jobs = base_scope.where(department: dept, status: "closed")
                               .where(closed_at: start_date..end_date)

      avg_days = if dept_jobs.any?
                   dept_jobs.map { |j| days_open(j) }.sum.to_f / dept_jobs.count
                 else
                   0
                 end

      {
        department_id: dept.id,
        department_name: dept.name,
        open_jobs: dept_jobs.count,
        avg_days_open: avg_days.round(1),
        filled_in_period: filled_jobs.count,
        total_applicants: Application.kept.joins(:job).where(jobs: { department_id: dept.id }).count
      }
    end.sort_by { |d| -d[:open_jobs] }
  end

  def overdue_requisitions
    target_days = 45

    open_jobs.select { |j| days_open(j) > target_days }
             .sort_by { |j| -days_open(j) }
             .first(10)
             .map do |job|
               {
                 id: job.id,
                 title: job.title,
                 department: job.department&.name,
                 recruiter: job.recruiter&.full_name,
                 hiring_manager: job.hiring_manager&.full_name,
                 days_open: days_open(job),
                 days_overdue: days_open(job) - target_days,
                 applicants: job.applications.kept.active.count,
                 last_activity: job.applications.maximum(:last_activity_at)
               }
             end
  end

  def fill_rate_trend
    weeks = []
    current_week = start_date.beginning_of_week

    while current_week <= end_date
      week_end = [current_week.end_of_week, end_date].min

      opened = base_scope.where(opened_at: current_week..week_end).count
      filled = base_scope.where(status: "closed")
                          .where(closed_at: current_week..week_end)
                          .where.not(filled_count: 0)
                          .count

      weeks << {
        week: current_week.to_date,
        label: current_week.strftime("%b %d"),
        opened: opened,
        filled: filled,
        net_change: opened - filled
      }

      current_week += 1.week
    end

    weeks
  end

  def days_open(job)
    return 0 unless job.opened_at

    ((Time.current - job.opened_at) / 1.day).to_i
  end

  def calculate_avg_days_open
    return 0 unless open_jobs.any?

    total_days = open_jobs.sum { |j| days_open(j) }
    (total_days.to_f / open_jobs.count).round(1)
  end
end
