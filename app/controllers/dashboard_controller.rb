# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    # Key metrics
    @open_jobs_count = Job.open_jobs.count
    @pending_approval_count = Job.by_status(:pending_approval).count
    @total_candidates_count = Candidate.kept.count
    @active_applications_count = Application.kept.active.count

    # Pipeline summary
    @applications_by_status = Application.kept.group(:status).count
    @new_applications_today = Application.kept.where("created_at >= ?", Time.current.beginning_of_day).count
    @new_applications_this_week = Application.kept.where("created_at >= ?", 1.week.ago).count

    # Task queue (actionable items)
    @pending_approvals = Job.by_status(:pending_approval)
                            .includes(:hiring_manager, :recruiter)
                            .order(created_at: :asc)
                            .limit(5)

    @stuck_applications = Application.kept.active
                                     .where("last_activity_at < ?", 7.days.ago)
                                     .includes(:candidate, :job, :current_stage)
                                     .order(last_activity_at: :asc)
                                     .limit(10)

    @starred_applications = Application.kept.starred.active
                                       .includes(:candidate, :job, :current_stage)
                                       .order(last_activity_at: :desc)
                                       .limit(5)

    # Recent activity
    @recent_activity = AuditLog.where(organization_id: current_organization.id)
                               .where("created_at >= ?", 24.hours.ago)
                               .includes(:user)
                               .recent
                               .limit(10)

    # Pipeline stats by stage (for open jobs)
    @pipeline_by_stage = Application.kept.active
                                    .joins(:current_stage)
                                    .group("stages.name")
                                    .count

    # Recent hires
    @recent_hires = Application.kept.where(status: "hired")
                               .where("hired_at >= ?", 30.days.ago)
                               .includes(:candidate, :job)
                               .order(hired_at: :desc)
                               .limit(5)

    # SLA alerts (candidates stuck too long)
    @sla_alerts = calculate_sla_alerts
  end

  private

  def calculate_sla_alerts
    alerts = []

    # Critical: > 14 days in stage
    critical_count = Application.kept.active
                                .where("last_activity_at < ?", 14.days.ago)
                                .count
    if critical_count > 0
      alerts << {
        level: :critical,
        message: "#{critical_count} candidate#{'s' if critical_count > 1} stuck for over 14 days",
        icon: "exclamation-triangle-fill",
        color: "danger"
      }
    end

    # Warning: > 7 days in stage
    warning_count = Application.kept.active
                               .where("last_activity_at < ? AND last_activity_at >= ?", 7.days.ago, 14.days.ago)
                               .count
    if warning_count > 0
      alerts << {
        level: :warning,
        message: "#{warning_count} candidate#{'s' if warning_count > 1} need attention (7+ days)",
        icon: "clock",
        color: "warning"
      }
    end

    # Info: Jobs with no activity
    stale_jobs = Job.open_jobs
                    .left_joins(:applications)
                    .where(applications: { id: nil })
                    .count
    if stale_jobs > 0
      alerts << {
        level: :info,
        message: "#{stale_jobs} open job#{'s' if stale_jobs > 1} with no applicants",
        icon: "info-circle",
        color: "info"
      }
    end

    alerts
  end
end
