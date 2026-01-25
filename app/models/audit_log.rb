# frozen_string_literal: true

# AuditLog provides an immutable record of all significant actions in the system.
# Once created, audit logs cannot be updated or deleted to maintain compliance.
#
# @example Creating an audit log
#   AuditLog.log!(
#     action: "job.status_changed",
#     auditable: job,
#     metadata: { from: "draft", to: "open" },
#     recorded_changes: job.saved_recorded_changes
#   )
#
class AuditLog < ApplicationRecord
  # Associations
  belongs_to :organization
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true

  # Validations
  validates :action, presence: true
  validates :auditable_type, presence: true
  validates :auditable_id, presence: true

  # Callbacks to enforce immutability
  before_update :prevent_update
  before_destroy :prevent_destroy

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) if action.present? }
  scope :by_user, ->(user_id) { where(user_id: user_id) if user_id.present? }
  scope :by_auditable_type, ->(type) { where(auditable_type: type) if type.present? }
  scope :by_date_range, ->(start_date, end_date) {
    scope = all
    scope = scope.where("created_at >= ?", start_date.beginning_of_day) if start_date.present?
    scope = scope.where("created_at <= ?", end_date.end_of_day) if end_date.present?
    scope
  }
  scope :today, -> { where("created_at >= ?", Time.current.beginning_of_day) }
  scope :this_week, -> { where("created_at >= ?", 1.week.ago) }

  # Action categories for filtering
  ACTION_CATEGORIES = {
    job: %w[job.created job.updated job.status_changed job.approved job.rejected job.archived],
    application: %w[application.created application.stage_changed application.rejected application.hired application.withdrawn],
    candidate: %w[candidate.created candidate.updated candidate.merged candidate.archived],
    user: %w[user.created user.updated user.deactivated user.role_changed user.signed_in],
    system: %w[system.import system.export system.setting_changed]
  }.freeze

  # Class methods for creating audit logs
  class << self
    # Create an audit log entry with current context
    def log!(action:, auditable:, metadata: {}, recorded_changes: {})
      create!(
        organization_id: auditable.try(:organization_id) || Current.organization&.id,
        user_id: Current.user&.id,
        action: action,
        auditable: auditable,
        metadata: metadata,
        recorded_changes: sanitize_recorded_changes(recorded_changes),
        ip_address: Current.ip_address,
        user_agent: Current.user_agent,
        request_id: Current.request_id
      )
    end

    # Safely create without raising (for non-critical logging)
    def log(action:, auditable:, metadata: {}, recorded_changes: {})
      log!(action: action, auditable: auditable, metadata: metadata, recorded_changes: recorded_changes)
    rescue StandardError => e
      Rails.logger.error("Failed to create audit log: #{e.message}")
      nil
    end

    private

    # Remove sensitive fields from recorded_changes hash
    def sanitize_recorded_changes(recorded_changes)
      return {} if recorded_changes.blank?

      sensitive_fields = %w[
        password encrypted_password password_digest
        ssn encrypted_ssn social_security_number
        credit_card card_number cvv
        secret token api_key
      ]

      recorded_changes.except(*sensitive_fields).transform_values do |value|
        # Truncate very long values
        if value.is_a?(Array) && value.any? { |v| v.is_a?(String) && v.length > 1000 }
          value.map { |v| v.is_a?(String) && v.length > 1000 ? "#{v[0..997]}..." : v }
        else
          value
        end
      end
    end
  end

  # Display helpers
  def action_label
    action.split(".").last.titleize
  end

  def action_category
    action.split(".").first
  end

  def user_display_name
    user&.display_name || "System"
  end

  def auditable_display_name
    case auditable_type
    when "Job"
      auditable&.title || "Job ##{auditable_id}"
    when "Application"
      auditable&.candidate&.full_name || "Application ##{auditable_id}"
    when "Candidate"
      auditable&.full_name || "Candidate ##{auditable_id}"
    when "User"
      auditable&.display_name || "User ##{auditable_id}"
    else
      "#{auditable_type} ##{auditable_id}"
    end
  end

  def recorded_changes_summary
    return "" if self.recorded_changes.blank?

    self.recorded_changes.map do |field, values|
      if values.is_a?(Array) && values.length == 2
        "#{field.humanize}: #{values[0] || 'nil'} → #{values[1] || 'nil'}"
      else
        "#{field.humanize}: #{values}"
      end
    end.join(", ")
  end

  private

  def prevent_update
    raise ActiveRecord::ReadOnlyRecord, "Audit logs cannot be modified"
  end

  def prevent_destroy
    raise ActiveRecord::ReadOnlyRecord, "Audit logs cannot be deleted"
  end
end
