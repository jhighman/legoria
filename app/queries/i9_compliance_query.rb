# frozen_string_literal: true

# Query object for I-9 compliance analytics
# Calculates completion rates, timing metrics, and compliance status
class I9ComplianceQuery < ApplicationQuery
  option :start_date
  option :end_date
  option :status, optional: true
  option :department_id, optional: true

  def call
    {
      summary: summary_metrics,
      completion_rates: completion_rate_metrics,
      timing_metrics: timing_metrics,
      by_status: metrics_by_status,
      by_department: metrics_by_department,
      pending_deadlines: pending_deadline_data,
      overdue: overdue_data,
      late_completions: late_completion_data,
      trend: trend_data,
      raw_data: raw_verifications
    }
  end

  private

  def base_scope
    scope = scoped(I9Verification)
            .where(created_at: start_date.beginning_of_day..end_date.end_of_day)

    scope = scope.where(status: status) if status.present?
    scope = scope.joins(application: :job)
                 .where(jobs: { department_id: department_id }) if department_id.present?

    scope
  end

  def summary_metrics
    total = base_scope.count
    verified = base_scope.where(status: "verified").count
    pending = base_scope.where(status: %w[pending_section1 section1_complete pending_section2]).count
    failed = base_scope.where(status: %w[failed expired]).count
    late = base_scope.where(late_completion: true).count

    {
      total_verifications: total,
      verified: verified,
      pending: pending,
      failed: failed,
      late_completions: late,
      completion_rate: percentage(verified, total),
      late_rate: percentage(late, verified + failed)
    }
  end

  def completion_rate_metrics
    section1_complete = base_scope.where.not(section1_completed_at: nil).count
    section2_complete = base_scope.where.not(section2_completed_at: nil).count
    total = base_scope.count

    {
      section1_completion_rate: percentage(section1_complete, total),
      section2_completion_rate: percentage(section2_complete, total),
      full_completion_rate: percentage(section2_complete, total)
    }
  end

  def timing_metrics
    # Average time to complete Section 1 (from initiation)
    section1_times = base_scope
      .where.not(section1_completed_at: nil)
      .pluck(:created_at, :section1_completed_at)
      .map { |created, completed| (completed - created) / 1.hour }

    # Average time to complete Section 2 (from Section 1)
    section2_times = base_scope
      .where.not(section2_completed_at: nil)
      .pluck(:section1_completed_at, :section2_completed_at)
      .compact
      .map { |s1, s2| (s2 - s1) / 1.hour }

    # Total time (from initiation to verification)
    total_times = base_scope
      .where(status: "verified")
      .pluck(:created_at, :section2_completed_at)
      .map { |created, completed| (completed - created) / 1.hour }

    {
      avg_section1_hours: safe_average(section1_times),
      avg_section2_hours: safe_average(section2_times),
      avg_total_hours: safe_average(total_times),
      avg_section1_formatted: format_duration(safe_average(section1_times)),
      avg_section2_formatted: format_duration(safe_average(section2_times)),
      avg_total_formatted: format_duration(safe_average(total_times))
    }
  end

  def metrics_by_status
    base_scope
      .group(:status)
      .count
      .map do |status, count|
        {
          status: status,
          status_label: status.titleize.gsub("_", " "),
          count: count
        }
      end
      .sort_by { |s| status_order(s[:status]) }
  end

  def metrics_by_department
    base_scope
      .joins(application: { job: :department })
      .group("departments.id", "departments.name")
      .pluck("departments.id", "departments.name", Arel.sql("COUNT(*)"))
      .map do |dept_id, name, count|
        verified = scoped(I9Verification)
          .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
          .where(status: "verified")
          .joins(application: :job)
          .where(jobs: { department_id: dept_id })
          .count

        {
          department_id: dept_id,
          department_name: name,
          total: count,
          verified: verified,
          completion_rate: percentage(verified, count)
        }
      end
      .sort_by { |d| -d[:total] }
  end

  def pending_deadline_data
    today = Date.current

    {
      due_today: scoped(I9Verification)
        .where(status: %w[section1_complete pending_section2])
        .where(deadline_section2: today)
        .count,
      due_this_week: scoped(I9Verification)
        .where(status: %w[section1_complete pending_section2])
        .where(deadline_section2: today..today.end_of_week)
        .count,
      due_next_week: scoped(I9Verification)
        .where(status: %w[section1_complete pending_section2])
        .where(deadline_section2: (today + 1.week)..(today + 2.weeks))
        .count
    }
  end

  def overdue_data
    today = Date.current

    overdue_verifications = scoped(I9Verification)
      .where("deadline_section2 < ?", today)
      .where.not(status: %w[verified failed expired])
      .includes(:candidate, application: :job)
      .order(:deadline_section2)
      .limit(20)

    {
      count: overdue_verifications.except(:limit).count,
      verifications: overdue_verifications.map do |v|
        {
          id: v.id,
          candidate_name: v.candidate.full_name,
          job_title: v.application.job.title,
          deadline: v.deadline_section2,
          days_overdue: (today - v.deadline_section2).to_i,
          status: v.status
        }
      end
    }
  end

  def late_completion_data
    late_verifications = base_scope
      .where(late_completion: true)
      .includes(:candidate, application: :job)
      .order(section2_completed_at: :desc)
      .limit(20)

    {
      count: base_scope.where(late_completion: true).count,
      verifications: late_verifications.map do |v|
        {
          id: v.id,
          candidate_name: v.candidate.full_name,
          job_title: v.application.job.title,
          deadline: v.deadline_section2,
          completed_at: v.section2_completed_at,
          days_late: v.section2_completed_at.present? ?
            (v.section2_completed_at.to_date - v.deadline_section2).to_i : nil,
          reason: v.late_completion_reason
        }
      end
    }
  end

  def trend_data
    # Group by week for trend visualization
    weekly_data = base_scope.group_by { |v| v.created_at.beginning_of_week.to_date }

    weekly_data.map do |week, verifications|
      verified = verifications.count { |v| v.status == "verified" }
      late = verifications.count { |v| v.late_completion? }

      {
        week: week,
        label: week.strftime("%b %d"),
        total: verifications.size,
        verified: verified,
        late: late,
        completion_rate: percentage(verified, verifications.size)
      }
    end.sort_by { |t| t[:week] }
  end

  def raw_verifications
    base_scope
      .includes(:candidate, application: :job)
      .order(created_at: :desc)
      .limit(100)
      .map do |v|
        {
          id: v.id,
          candidate_name: v.candidate.full_name,
          job_title: v.application.job.title,
          status: v.status,
          created_at: v.created_at,
          deadline_section2: v.deadline_section2,
          section1_completed_at: v.section1_completed_at,
          section2_completed_at: v.section2_completed_at,
          late_completion: v.late_completion?,
          days_to_complete: v.section2_completed_at.present? ?
            (v.section2_completed_at.to_date - v.created_at.to_date).to_i : nil
        }
      end
  end

  def safe_average(array)
    return 0.0 if array.blank?

    array.sum.to_f / array.size
  end

  def status_order(status)
    order = {
      "pending_section1" => 0,
      "section1_complete" => 1,
      "pending_section2" => 2,
      "section2_complete" => 3,
      "pending_everify" => 4,
      "everify_tnc" => 5,
      "verified" => 6,
      "failed" => 7,
      "expired" => 8
    }
    order[status] || 99
  end
end
