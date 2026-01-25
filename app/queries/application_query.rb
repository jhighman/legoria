# frozen_string_literal: true

# Base class for read-only query objects
# Query objects encapsulate complex SQL/ActiveRecord aggregations
# and are always scoped to the current organization
class ApplicationQuery
  extend Dry::Initializer

  def self.call(...)
    new(...).call
  end

  private

  def organization
    Current.organization
  end

  def organization_id
    organization&.id
  end

  # Helper to scope queries to current organization
  def scoped(relation)
    relation.where(organization_id: organization_id)
  end

  # Date range helpers
  def date_range_condition(column, start_date, end_date)
    return {} unless start_date.present? && end_date.present?

    { column => start_date.beginning_of_day..end_date.end_of_day }
  end

  # Format duration in hours to human readable
  def format_duration(hours)
    return nil unless hours

    if hours < 24
      "#{hours.round(1)} hours"
    elsif hours < 168
      "#{(hours / 24.0).round(1)} days"
    else
      "#{(hours / 168.0).round(1)} weeks"
    end
  end

  # Calculate percentage safely
  def percentage(numerator, denominator)
    return 0.0 if denominator.nil? || denominator.zero?

    ((numerator.to_f / denominator) * 100).round(1)
  end
end
