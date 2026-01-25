# frozen_string_literal: true

# Phase 5: Logs for automation rule executions
class AutomationLog < ApplicationRecord
  include OrganizationScoped

  belongs_to :automation_rule
  belongs_to :application, optional: true
  belongs_to :candidate, optional: true

  # Statuses
  STATUSES = %w[success failed skipped].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :trigger_event, presence: true
  validates :triggered_at, presence: true

  # Scopes
  scope :successful, -> { where(status: "success") }
  scope :failed, -> { where(status: "failed") }
  scope :skipped, -> { where(status: "skipped") }
  scope :recent, -> { order(triggered_at: :desc) }
  scope :for_application, ->(app_id) { where(application_id: app_id) }
  scope :for_rule, ->(rule_id) { where(automation_rule_id: rule_id) }

  # Status checks
  def successful?
    status == "success"
  end

  def failed?
    status == "failed"
  end

  def skipped?
    status == "skipped"
  end
end
