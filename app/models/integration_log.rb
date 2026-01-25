# frozen_string_literal: true

# SA-11: Integration - Sync activity log
# Tracks all integration sync activities for debugging and audit
class IntegrationLog < ApplicationRecord
  include OrganizationScoped

  # Associations
  belongs_to :integration

  # Status constants
  STATUSES = %w[success failed partial].freeze
  DIRECTIONS = %w[inbound outbound].freeze

  # Validations
  validates :action, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :direction, presence: true, inclusion: { in: DIRECTIONS }
  validates :started_at, presence: true

  # Scopes
  scope :successful, -> { where(status: "success") }
  scope :failed, -> { where(status: "failed") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) }
  scope :for_resource, ->(type, id) { where(resource_type: type, resource_id: id) }

  # Instance methods
  def success?
    status == "success"
  end

  def failed?
    status == "failed"
  end

  def partial?
    status == "partial"
  end

  def complete!(success: true, records_processed: 0, records_created: 0, records_updated: 0, records_failed: 0)
    update!(
      status: success ? "success" : "failed",
      completed_at: Time.current,
      records_processed: records_processed,
      records_created: records_created,
      records_updated: records_updated,
      records_failed: records_failed
    )
  end

  # Common actions
  ACTIONS = %w[
    sync_jobs
    sync_candidates
    post_job
    remove_job
    submit_background_check
    get_background_check_status
    export_to_hris
    refresh_token
    webhook_received
    test_connection
  ].freeze
end
