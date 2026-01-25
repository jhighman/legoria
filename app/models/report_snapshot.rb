# frozen_string_literal: true

class ReportSnapshot < ApplicationRecord
  include OrganizationScoped

  REPORT_TYPES = %w[eeoc diversity pipeline time_to_hire source_effectiveness operational].freeze
  PERIOD_TYPES = %w[daily weekly monthly quarterly yearly].freeze

  # Associations
  belongs_to :generated_by, class_name: "User", optional: true

  # Validations
  validates :report_type, presence: true, inclusion: { in: REPORT_TYPES }
  validates :period_type, presence: true, inclusion: { in: PERIOD_TYPES }
  validates :period_start, presence: true
  validates :period_end, presence: true
  validates :generated_at, presence: true
  validates :data, presence: true

  validate :period_end_after_start

  # Scopes
  scope :by_type, ->(type) { where(report_type: type) }
  scope :by_period_type, ->(type) { where(period_type: type) }
  scope :recent, -> { order(generated_at: :desc) }
  scope :for_period, ->(start_date, end_date) {
    where("period_start >= ? AND period_end <= ?", start_date, end_date)
  }

  # Find or generate a snapshot for the given parameters
  def self.find_or_generate(report_type:, period_type:, period_start:, period_end:)
    existing = where(
      report_type: report_type,
      period_type: period_type,
      period_start: period_start,
      period_end: period_end
    ).order(generated_at: :desc).first

    # Return existing if generated recently (within 24 hours for daily, 1 week for others)
    cache_duration = period_type == "daily" ? 24.hours : 1.week
    return existing if existing && existing.generated_at > cache_duration.ago

    # Generate new snapshot
    generate(
      report_type: report_type,
      period_type: period_type,
      period_start: period_start,
      period_end: period_end
    )
  end

  # Generate a new snapshot
  def self.generate(report_type:, period_type:, period_start:, period_end:, generated_by: nil)
    data = case report_type
           when "eeoc"
             EeocReportQuery.call(start_date: period_start, end_date: period_end)
           when "diversity"
             DiversityMetricsQuery.call(start_date: period_start, end_date: period_end)
           when "pipeline"
             PipelineConversionQuery.call(start_date: period_start, end_date: period_end)
           when "time_to_hire"
             TimeToHireQuery.call(start_date: period_start, end_date: period_end)
           when "source_effectiveness"
             SourceEffectivenessQuery.call(start_date: period_start, end_date: period_end)
           when "operational"
             {
               productivity: RecruiterProductivityQuery.call(start_date: period_start, end_date: period_end),
               aging: RequisitionAgingQuery.call(start_date: period_start, end_date: period_end)
             }
           else
             {}
           end

    create!(
      report_type: report_type,
      period_type: period_type,
      period_start: period_start,
      period_end: period_end,
      data: data,
      generated_at: Time.current,
      generated_by: generated_by,
      metadata: {
        generator_version: "1.0",
        organization_name: Current.organization&.name
      }
    )
  end

  # Get historical snapshots for trend comparison
  def self.historical_trend(report_type:, period_type:, count: 12)
    by_type(report_type)
      .by_period_type(period_type)
      .recent
      .limit(count)
      .order(period_start: :asc)
  end

  # Display helpers
  def period_label
    case period_type
    when "daily"
      period_start.strftime("%b %d, %Y")
    when "weekly"
      "Week of #{period_start.strftime('%b %d, %Y')}"
    when "monthly"
      period_start.strftime("%B %Y")
    when "quarterly"
      "Q#{((period_start.month - 1) / 3) + 1} #{period_start.year}"
    when "yearly"
      period_start.year.to_s
    end
  end

  def report_type_label
    report_type.titleize
  end

  def generated_by_name
    generated_by&.full_name || "System"
  end

  def stale?
    cache_duration = period_type == "daily" ? 24.hours : 1.week
    generated_at < cache_duration.ago
  end

  private

  def period_end_after_start
    return unless period_start.present? && period_end.present?

    if period_end < period_start
      errors.add(:period_end, "must be after period start")
    end
  end
end
