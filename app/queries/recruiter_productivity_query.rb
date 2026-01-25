# frozen_string_literal: true

# Query object for recruiter productivity analytics
# Tracks recruiter activity metrics and performance
class RecruiterProductivityQuery < ApplicationQuery
  option :start_date
  option :end_date

  def call
    {
      summary: summary_metrics,
      by_recruiter: recruiter_breakdown,
      activity_trend: activity_trend,
      rankings: performance_rankings
    }
  end

  private

  def recruiters
    @recruiters ||= User.joins(:roles)
                        .where(roles: { name: %w[recruiter admin] })
                        .distinct
  end

  def summary_metrics
    total_hires = Application.kept.where(status: "hired", hired_at: start_date..end_date).count
    total_interviews = Interview.where(created_at: start_date..end_date).count
    total_offers = Offer.where(created_at: start_date..end_date).count
    active_recruiters = recruiters.count

    {
      total_hires: total_hires,
      total_interviews_scheduled: total_interviews,
      total_offers_made: total_offers,
      active_recruiters: active_recruiters,
      avg_hires_per_recruiter: active_recruiters.positive? ? (total_hires.to_f / active_recruiters).round(1) : 0
    }
  end

  def recruiter_breakdown
    recruiters.map do |recruiter|
      jobs = Job.where(recruiter_id: recruiter.id)
      job_ids = jobs.pluck(:id)

      applications_received = Application.kept
                                         .where(job_id: job_ids)
                                         .where(applied_at: start_date..end_date)
                                         .count

      stage_moves = StageTransition.joins(:application)
                                   .where(moved_by_id: recruiter.id)
                                   .where(created_at: start_date..end_date)
                                   .count

      interviews_scheduled = Interview.joins(:application)
                                      .where(applications: { job_id: job_ids })
                                      .where(created_at: start_date..end_date)
                                      .count

      offers_made = Offer.joins(:application)
                         .where(applications: { job_id: job_ids })
                         .where(created_at: start_date..end_date)
                         .count

      hires = Application.kept
                         .where(job_id: job_ids, status: "hired")
                         .where(hired_at: start_date..end_date)
                         .count

      {
        recruiter_id: recruiter.id,
        recruiter_name: recruiter.full_name,
        active_jobs: jobs.open_jobs.count,
        applications_received: applications_received,
        stage_moves: stage_moves,
        interviews_scheduled: interviews_scheduled,
        offers_made: offers_made,
        hires: hires,
        conversion_rate: applications_received.positive? ? percentage(hires, applications_received) : 0
      }
    end.sort_by { |r| -r[:hires] }
  end

  def activity_trend
    weeks = []
    current_week = start_date.beginning_of_week

    while current_week <= end_date
      week_end = [current_week.end_of_week, end_date].min

      stage_moves = StageTransition.where(created_at: current_week..week_end).count
      interviews = Interview.where(created_at: current_week..week_end).count
      hires = Application.kept.where(status: "hired", hired_at: current_week..week_end).count

      weeks << {
        week: current_week.to_date,
        label: current_week.strftime("%b %d"),
        stage_moves: stage_moves,
        interviews: interviews,
        hires: hires
      }

      current_week += 1.week
    end

    weeks
  end

  def performance_rankings
    breakdown = recruiter_breakdown

    {
      most_hires: breakdown.sort_by { |r| -r[:hires] }.first(3),
      highest_conversion: breakdown.select { |r| r[:applications_received] >= 10 }
                                   .sort_by { |r| -r[:conversion_rate] }
                                   .first(3),
      most_active: breakdown.sort_by { |r| -(r[:stage_moves] + r[:interviews_scheduled]) }.first(3)
    }
  end
end
