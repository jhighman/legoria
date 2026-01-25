# frozen_string_literal: true

# Concern for handling date range filtering in report controllers
# Supports predefined ranges and custom date inputs
module DateRangeFilter
  extend ActiveSupport::Concern

  PRESET_RANGES = %w[
    today
    this_week
    this_month
    this_quarter
    this_year
    last_7_days
    last_30_days
    last_90_days
    custom
  ].freeze

  included do
    helper_method :date_range_preset, :start_date, :end_date, :preset_range_options
  end

  private

  def date_range_preset
    @date_range_preset ||= params[:range].presence || "last_30_days"
  end

  def start_date
    @start_date ||= calculate_start_date
  end

  def end_date
    @end_date ||= calculate_end_date
  end

  def calculate_start_date
    case date_range_preset
    when "today"
      Time.current.beginning_of_day
    when "this_week"
      Time.current.beginning_of_week
    when "this_month"
      Time.current.beginning_of_month
    when "this_quarter"
      Time.current.beginning_of_quarter
    when "this_year"
      Time.current.beginning_of_year
    when "last_7_days"
      7.days.ago.beginning_of_day
    when "last_30_days"
      30.days.ago.beginning_of_day
    when "last_90_days"
      90.days.ago.beginning_of_day
    when "custom"
      parse_custom_date(params[:start_date], 30.days.ago)
    else
      30.days.ago.beginning_of_day
    end
  end

  def calculate_end_date
    case date_range_preset
    when "today"
      Time.current.end_of_day
    when "this_week"
      Time.current.end_of_week
    when "this_month"
      Time.current.end_of_month
    when "this_quarter"
      Time.current.end_of_quarter
    when "this_year"
      Time.current.end_of_year
    when "custom"
      parse_custom_date(params[:end_date], Time.current)
    else
      Time.current.end_of_day
    end
  end

  def parse_custom_date(date_string, fallback)
    return fallback.to_date unless date_string.present?

    Date.parse(date_string)
  rescue ArgumentError
    fallback.to_date
  end

  def preset_range_options
    [
      ["Today", "today"],
      ["This Week", "this_week"],
      ["This Month", "this_month"],
      ["This Quarter", "this_quarter"],
      ["This Year", "this_year"],
      ["Last 7 Days", "last_7_days"],
      ["Last 30 Days", "last_30_days"],
      ["Last 90 Days", "last_90_days"],
      ["Custom Range", "custom"]
    ]
  end

  def date_range_label
    case date_range_preset
    when "today" then "Today"
    when "this_week" then "This Week"
    when "this_month" then "This Month"
    when "this_quarter" then "This Quarter"
    when "this_year" then "This Year"
    when "last_7_days" then "Last 7 Days"
    when "last_30_days" then "Last 30 Days"
    when "last_90_days" then "Last 90 Days"
    when "custom" then "#{start_date.strftime('%b %d, %Y')} - #{end_date.strftime('%b %d, %Y')}"
    else "Last 30 Days"
    end
  end
end
