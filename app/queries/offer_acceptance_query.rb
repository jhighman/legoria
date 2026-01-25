# frozen_string_literal: true

# Query object for offer acceptance analytics
# Tracks offer volume, acceptance rates, and decline reasons
class OfferAcceptanceQuery < ApplicationQuery
  option :start_date
  option :end_date
  option :job_id, optional: true
  option :department_id, optional: true

  def call
    {
      summary: summary_metrics,
      by_job: metrics_by_job,
      by_department: metrics_by_department,
      trend: weekly_trend,
      time_to_decision: time_to_decision_metrics
    }
  end

  private

  def base_scope
    scope = Offer.joins(:application)
                 .where(created_at: start_date..end_date)

    scope = scope.where(applications: { job_id: job_id }) if job_id.present?
    if department_id.present?
      scope = scope.joins(application: :job).where(jobs: { department_id: department_id })
    end
    scope
  end

  def summary_metrics
    total = base_scope.count
    accepted = base_scope.where(status: "accepted").count
    declined = base_scope.where(status: "declined").count
    pending = base_scope.where(status: %w[sent approved pending_approval]).count
    expired = base_scope.where(status: "expired").count
    withdrawn = base_scope.where(status: "withdrawn").count

    {
      total_offers: total,
      accepted: accepted,
      declined: declined,
      pending: pending,
      expired: expired,
      withdrawn: withdrawn,
      acceptance_rate: percentage(accepted, accepted + declined),
      decline_rate: percentage(declined, accepted + declined)
    }
  end

  def metrics_by_job
    jobs_data = base_scope
      .joins(application: :job)
      .group("jobs.id", "jobs.title")
      .select("jobs.id, jobs.title, COUNT(*) as total")
      .map { |r| [r.id, r.title, r.total] }

    jobs_data.map do |job_id, title, total|
      job_offers = base_scope.joins(:application).where(applications: { job_id: job_id })
      accepted = job_offers.where(status: "accepted").count
      declined = job_offers.where(status: "declined").count

      {
        job_id: job_id,
        job_title: title,
        offers: total,
        accepted: accepted,
        declined: declined,
        acceptance_rate: percentage(accepted, accepted + declined)
      }
    end.sort_by { |j| -j[:offers] }
  end

  def metrics_by_department
    dept_data = base_scope
      .joins(application: { job: :department })
      .group("departments.id", "departments.name")
      .count

    dept_data.map do |dept_key, count|
      dept_id, name = dept_key

      dept_offers = base_scope
        .joins(application: { job: :department })
        .where(departments: { id: dept_id })

      accepted = dept_offers.where(status: "accepted").count
      declined = dept_offers.where(status: "declined").count

      {
        department_id: dept_id,
        department_name: name,
        offers: count,
        accepted: accepted,
        declined: declined,
        acceptance_rate: percentage(accepted, accepted + declined)
      }
    end.sort_by { |d| -d[:offers] }
  end

  def weekly_trend
    weeks = []
    current_week = start_date.beginning_of_week

    while current_week <= end_date
      week_end = [current_week.end_of_week, end_date].min

      week_offers = Offer.joins(:application)
                         .where(created_at: current_week..week_end)

      week_offers = week_offers.where(applications: { job_id: job_id }) if job_id.present?

      total = week_offers.count
      accepted = week_offers.where(status: "accepted").count
      declined = week_offers.where(status: "declined").count

      weeks << {
        week: current_week.to_date,
        label: current_week.strftime("%b %d"),
        offers: total,
        accepted: accepted,
        declined: declined,
        acceptance_rate: percentage(accepted, accepted + declined)
      }

      current_week += 1.week
    end

    weeks
  end

  def time_to_decision_metrics
    # Calculate average time from offer sent to decision
    decided_offers = base_scope
      .where(status: %w[accepted declined])
      .where.not(sent_at: nil)

    return { average_days: 0, median_days: 0 } unless decided_offers.exists?

    days = decided_offers.map do |offer|
      decided_at = offer.accepted_at || offer.declined_at || offer.updated_at
      (decided_at.to_date - offer.sent_at.to_date).to_i
    end.compact

    return { average_days: 0, median_days: 0 } if days.empty?

    {
      average_days: (days.sum.to_f / days.size).round(1),
      median_days: calculate_median(days),
      fastest: days.min,
      slowest: days.max
    }
  end

  def calculate_median(array)
    return 0 if array.empty?

    sorted = array.sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end
end
