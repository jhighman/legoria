# frozen_string_literal: true

# SA-11: Integration - HRIS export tracking
# Records exports of hired candidates to HRIS systems
class HrisExport < ApplicationRecord
  include OrganizationScoped

  # Associations
  belongs_to :integration
  belongs_to :application
  belongs_to :candidate
  belongs_to :exported_by, class_name: "User"

  # Status workflow
  STATUSES = %w[pending exporting completed failed cancelled].freeze

  # Validations
  validates :status, inclusion: { in: STATUSES }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }
  scope :recent, -> { order(created_at: :desc) }

  # State checks
  def pending?
    status == "pending"
  end

  def exporting?
    status == "exporting"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def cancelled?
    status == "cancelled"
  end

  # Workflow actions
  def start_export!(export_data:, field_mapping: nil)
    return false unless pending?

    update!(
      status: "exporting",
      export_data: export_data,
      field_mapping: field_mapping,
      exported_at: Time.current
    )
  end

  def complete!(external_id:, external_url: nil, response_data: nil)
    return false unless exporting?

    update!(
      status: "completed",
      external_id: external_id,
      external_url: external_url,
      response_data: response_data,
      confirmed_at: Time.current
    )
  end

  def fail!(error_message:, response_data: nil)
    return false unless exporting?

    update!(
      status: "failed",
      error_message: error_message,
      response_data: response_data
    )
  end

  def cancel!
    return false if completed?

    update!(status: "cancelled")
  end

  def retry!
    return false unless failed?

    update!(status: "pending", error_message: nil, response_data: nil)
  end
end
