# frozen_string_literal: true

class DataRetentionPolicy < ApplicationRecord
  include OrganizationScoped

  # Data categories
  DATA_CATEGORIES = %w[candidate_data application_data interview_data offer_data eeoc_data].freeze
  RETENTION_TRIGGERS = %w[application_closed candidate_withdrawn offer_declined hired].freeze
  ACTION_TYPES = %w[anonymize delete archive].freeze

  # Associations
  # None - this is a policy configuration

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :data_category, presence: true, inclusion: { in: DATA_CATEGORIES }
  validates :retention_days, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 3650 }
  validates :retention_trigger, presence: true, inclusion: { in: RETENTION_TRIGGERS }
  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }

  validate :unique_category_per_organization

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_category, ->(category) { where(data_category: category) if category.present? }
  scope :by_trigger, ->(trigger) { where(retention_trigger: trigger) if trigger.present? }

  # Category helpers
  def candidate_data?
    data_category == "candidate_data"
  end

  def application_data?
    data_category == "application_data"
  end

  def interview_data?
    data_category == "interview_data"
  end

  def offer_data?
    data_category == "offer_data"
  end

  def eeoc_data?
    data_category == "eeoc_data"
  end

  # Action helpers
  def anonymize?
    action_type == "anonymize"
  end

  def delete?
    action_type == "delete"
  end

  def archive?
    action_type == "archive"
  end

  # Display helpers
  def data_category_label
    data_category.titleize.gsub("_", " ")
  end

  def retention_trigger_label
    retention_trigger.titleize.gsub("_", " ")
  end

  def action_type_label
    action_type.titleize
  end

  def retention_period_label
    if retention_days >= 365
      years = retention_days / 365
      "#{years} year#{'s' if years > 1}"
    elsif retention_days >= 30
      months = retention_days / 30
      "#{months} month#{'s' if months > 1}"
    else
      "#{retention_days} day#{'s' if retention_days > 1}"
    end
  end

  # Calculation helpers
  def calculate_deletion_date(trigger_date)
    trigger_date + retention_days.days
  end

  def should_process?(trigger_date)
    calculate_deletion_date(trigger_date) <= Date.current
  end

  # Activation
  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end

  private

  def unique_category_per_organization
    return unless active?

    existing = organization.data_retention_policies
                          .active
                          .where(data_category: data_category)
                          .where.not(id: id)

    if existing.exists?
      errors.add(:data_category, "already has an active policy for this organization")
    end
  end
end
