# frozen_string_literal: true

# Auditable concern automatically logs model lifecycle events to AuditLog.
#
# Include this concern in any model that should have its changes tracked:
#
#   class Job < ApplicationRecord
#     include Auditable
#   end
#
# This will automatically create audit logs for:
# - create events
# - update events (with changes)
# - destroy events
#
# You can customize the audit action names and exclude certain attributes:
#
#   class Job < ApplicationRecord
#     include Auditable
#
#     audit_actions create: "job.created", update: "job.updated", destroy: "job.archived"
#     audit_exclude :internal_notes, :cached_data
#   end
#
module Auditable
  extend ActiveSupport::Concern

  included do
    # Default audit configuration
    class_attribute :audit_action_names, default: {}
    class_attribute :audit_excluded_attributes, default: []
    class_attribute :audit_enabled, default: true

    # Callbacks
    after_create :audit_create, if: :should_audit?
    after_update :audit_update, if: :should_audit?
    after_destroy :audit_destroy, if: :should_audit?
  end

  class_methods do
    # Configure custom action names for audit events
    #
    # @example
    #   audit_actions create: "job.created", update: "job.updated"
    #
    def audit_actions(actions = {})
      self.audit_action_names = actions.with_indifferent_access
    end

    # Exclude attributes from being logged in changes
    #
    # @example
    #   audit_exclude :internal_notes, :cached_data
    #
    def audit_exclude(*attributes)
      self.audit_excluded_attributes = attributes.map(&:to_s)
    end

    # Disable auditing for this model
    def skip_audit!
      self.audit_enabled = false
    end
  end

  # Allow manual audit logging for custom events (public method)
  def audit!(action, metadata: {}, recorded_changes: {})
    AuditLog.log!(
      action: action,
      auditable: self,
      metadata: audit_metadata_for(:custom).merge(metadata),
      recorded_changes: recorded_changes
    )
  end

  private

  def should_audit?
    audit_enabled && Current.organization.present?
  end

  def audit_create
    AuditLog.log(
      action: audit_action_for(:create),
      auditable: self,
      metadata: audit_metadata_for(:create),
      recorded_changes: {}
    )
  end

  def audit_update
    return if filtered_changes.empty?

    AuditLog.log(
      action: audit_action_for(:update),
      auditable: self,
      metadata: audit_metadata_for(:update),
      recorded_changes: filtered_changes
    )
  end

  def audit_destroy
    AuditLog.log(
      action: audit_action_for(:destroy),
      auditable: self,
      metadata: audit_metadata_for(:destroy),
      recorded_changes: {}
    )
  end

  def audit_action_for(event)
    audit_action_names[event] || "#{self.class.name.underscore}.#{event}d"
  end

  def audit_metadata_for(event)
    base_metadata = {
      model: self.class.name,
      record_id: id
    }

    # Add custom metadata based on model type
    case self
    when Job
      base_metadata.merge(
        title: title,
        status: status,
        department: department&.name
      )
    when Application
      base_metadata.merge(
        job_title: job&.title,
        candidate_name: candidate&.full_name,
        status: status,
        stage: current_stage&.name
      )
    when Candidate
      base_metadata.merge(
        name: full_name
      )
    when User
      base_metadata.merge(
        email: email,
        name: display_name
      )
    else
      base_metadata
    end
  end

  def filtered_changes
    # Get saved changes and exclude unwanted attributes
    changes = saved_changes.except(
      "created_at", "updated_at", "last_activity_at",
      *audit_excluded_attributes
    )

    # Don't log password changes content, just that it changed
    if changes.key?("encrypted_password")
      changes["password"] = ["[FILTERED]", "[FILTERED]"]
      changes.delete("encrypted_password")
    end

    changes
  end
end
