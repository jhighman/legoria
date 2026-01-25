# frozen_string_literal: true

class Permission < ApplicationRecord
  # Associations
  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  # Validations
  validates :resource, presence: true
  validates :action, presence: true
  validates :action, uniqueness: { scope: :resource }

  # Scopes
  scope :for_resource, ->(resource) { where(resource: resource) }

  # Class method to seed default permissions
  def self.seed_defaults
    default_permissions.each do |perm|
      find_or_create_by!(resource: perm[:resource], action: perm[:action]) do |p|
        p.description = perm[:description]
      end
    end
  end

  def self.default_permissions
    [
      # Jobs
      { resource: "jobs", action: "create", description: "Create job requisitions" },
      { resource: "jobs", action: "read", description: "View job requisitions" },
      { resource: "jobs", action: "update", description: "Edit job requisitions" },
      { resource: "jobs", action: "delete", description: "Delete job requisitions" },
      { resource: "jobs", action: "approve", description: "Approve job requisitions" },

      # Candidates
      { resource: "candidates", action: "create", description: "Add candidates" },
      { resource: "candidates", action: "read", description: "View candidates" },
      { resource: "candidates", action: "update", description: "Edit candidates" },
      { resource: "candidates", action: "delete", description: "Delete candidates" },

      # Applications
      { resource: "applications", action: "create", description: "Create applications" },
      { resource: "applications", action: "read", description: "View applications" },
      { resource: "applications", action: "update", description: "Update applications" },
      { resource: "applications", action: "delete", description: "Delete applications" },
      { resource: "applications", action: "move_stage", description: "Move applications between stages" },
      { resource: "applications", action: "reject", description: "Reject applications" },

      # Users
      { resource: "users", action: "create", description: "Create users" },
      { resource: "users", action: "read", description: "View users" },
      { resource: "users", action: "update", description: "Edit users" },
      { resource: "users", action: "delete", description: "Delete users" },

      # Settings
      { resource: "settings", action: "read", description: "View settings" },
      { resource: "settings", action: "update", description: "Update settings" },

      # Reports
      { resource: "reports", action: "read", description: "View reports" },
      { resource: "reports", action: "export", description: "Export reports" },

      # Compliance
      { resource: "compliance", action: "read", description: "View compliance data" },
      { resource: "compliance", action: "manage", description: "Manage compliance" }
    ]
  end

  def full_name
    "#{resource}:#{action}"
  end
end
