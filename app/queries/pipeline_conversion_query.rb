# frozen_string_literal: true

# Query object for pipeline conversion analytics
# Calculates stage-to-stage conversion rates using StageTransition data
class PipelineConversionQuery < ApplicationQuery
  option :start_date
  option :end_date
  option :job_id, optional: true
  option :department_id, optional: true

  def call
    {
      funnel: funnel_data,
      stage_metrics: stage_metrics,
      conversion_matrix: conversion_matrix,
      bottlenecks: identify_bottlenecks,
      trend: conversion_trend
    }
  end

  private

  def base_transitions
    scope = StageTransition.joins(:application)
                           .where(created_at: start_date..end_date)
                           .where(applications: { discarded_at: nil })

    scope = scope.where(applications: { job_id: job_id }) if job_id.present?
    if department_id.present?
      scope = scope.joins(application: :job).where(jobs: { department_id: department_id })
    end
    scope
  end

  def stages
    @stages ||= Stage.where(is_default: true)
                     .where(is_terminal: false)
                     .order(:position)
  end

  def funnel_data
    stages.map.with_index do |stage, index|
      entries = count_stage_entries(stage.id)
      exits = count_stage_exits(stage.id)

      # First stage doesn't have a "from" conversion
      conversion_from_previous = if index.zero?
                                   100.0
                                 else
                                   prev_stage = stages[index - 1]
                                   prev_entries = count_stage_entries(prev_stage.id)
                                   prev_entries.positive? ? percentage(entries, prev_entries) : 0
                                 end

      {
        stage_id: stage.id,
        stage_name: stage.name,
        stage_color: stage.color,
        position: stage.position,
        entries: entries,
        exits: exits,
        conversion_from_previous: conversion_from_previous,
        avg_time_in_stage: calculate_avg_time(stage.id)
      }
    end
  end

  def stage_metrics
    stages.map do |stage|
      entries = count_stage_entries(stage.id)
      exits = count_stage_exits(stage.id)
      rejections = count_rejections_from_stage(stage.id)

      {
        stage_id: stage.id,
        stage_name: stage.name,
        entries: entries,
        exits: exits,
        rejections: rejections,
        pass_through_rate: entries.positive? ? percentage(exits, entries) : 0,
        rejection_rate: entries.positive? ? percentage(rejections, entries) : 0,
        avg_time_hours: calculate_avg_time(stage.id),
        current_count: current_in_stage(stage.id)
      }
    end
  end

  def conversion_matrix
    # Matrix showing conversion from each stage to each subsequent stage
    matrix = {}

    stages.each_with_index do |from_stage, from_idx|
      matrix[from_stage.name] = {}

      stages.each_with_index do |to_stage, to_idx|
        next if to_idx <= from_idx

        count = base_transitions
                  .where(from_stage_id: from_stage.id, to_stage_id: to_stage.id)
                  .count

        matrix[from_stage.name][to_stage.name] = count
      end
    end

    matrix
  end

  def identify_bottlenecks
    # Stages with below-average conversion rates
    metrics = stage_metrics
    avg_pass_rate = metrics.sum { |m| m[:pass_through_rate] } / metrics.size.to_f

    metrics.select { |m| m[:pass_through_rate] < avg_pass_rate && m[:entries] > 5 }
           .sort_by { |m| m[:pass_through_rate] }
           .first(3)
           .map do |m|
             {
               stage_name: m[:stage_name],
               pass_through_rate: m[:pass_through_rate],
               avg_rate: avg_pass_rate.round(1),
               gap: (avg_pass_rate - m[:pass_through_rate]).round(1),
               recommendation: bottleneck_recommendation(m)
             }
           end
  end

  def conversion_trend
    # Weekly conversion rates
    weeks = []
    current_week = start_date.beginning_of_week

    while current_week <= end_date
      week_end = [current_week.end_of_week, end_date].min

      week_transitions = StageTransition.joins(:application)
                                        .where(created_at: current_week..week_end)
                                        .where(applications: { discarded_at: nil })

      week_transitions = week_transitions.where(applications: { job_id: job_id }) if job_id.present?

      total_apps = Application.kept.where(applied_at: current_week..week_end).count
      hired = Application.kept.where(status: "hired", hired_at: current_week..week_end).count

      weeks << {
        week: current_week.to_date,
        label: current_week.strftime("%b %d"),
        applications: total_apps,
        hires: hired,
        overall_conversion: total_apps.positive? ? percentage(hired, total_apps) : 0
      }

      current_week += 1.week
    end

    weeks
  end

  def count_stage_entries(stage_id)
    base_transitions.where(to_stage_id: stage_id).count
  end

  def count_stage_exits(stage_id)
    base_transitions.where(from_stage_id: stage_id).count
  end

  def count_rejections_from_stage(stage_id)
    Application.kept
               .where(status: "rejected")
               .joins(:stage_transitions)
               .where(stage_transitions: { from_stage_id: stage_id })
               .distinct
               .count
  end

  def calculate_avg_time(stage_id)
    StageTransition.average_time_in_stage(stage_id) || 0
  end

  def current_in_stage(stage_id)
    Application.kept.active.where(current_stage_id: stage_id).count
  end

  def bottleneck_recommendation(metrics)
    if metrics[:rejection_rate] > 50
      "High rejection rate - review screening criteria"
    elsif metrics[:avg_time_hours] && metrics[:avg_time_hours] > 168 # 1 week
      "Long stage duration - consider process optimization"
    else
      "Below-average conversion - analyze candidate feedback"
    end
  end
end
