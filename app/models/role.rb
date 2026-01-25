# frozen_string_literal: true

class Role < ApplicationRecord
  include OrganizationScoped

  # Associations
  has_many :role_permissions, dependent: :destroy
  has_many :linked_permissions, through: :role_permissions, source: :permission
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  # Validations
  validates :name, presence: true,
                   length: { maximum: 100 },
                   uniqueness: { scope: :organization_id, case_sensitive: false }

  # Scopes
  scope :system_roles, -> { where(system_role: true) }
  scope :custom_roles, -> { where(system_role: false) }

  # Check if role has a specific permission
  def has_permission?(resource, action)
    # Check JSON permissions field
    return true if permissions&.dig(resource.to_s)&.include?(action.to_s)

    # Check role_permissions table
    role_permissions.joins(:permission)
                    .exists?(permissions: { resource: resource, action: action })
  end

  # Add permission to role
  def grant_permission(resource, action)
    self.permissions ||= {}
    self.permissions[resource.to_s] ||= []
    self.permissions[resource.to_s] << action.to_s unless self.permissions[resource.to_s].include?(action.to_s)
  end

  # Remove permission from role
  def revoke_permission(resource, action)
    return unless permissions&.dig(resource.to_s)

    self.permissions[resource.to_s].delete(action.to_s)
  end

  # System role check
  def system_role?
    system_role
  end

  # Built-in role checks
  def admin?
    name == "admin" && system_role?
  end

  def recruiter?
    name == "recruiter" && system_role?
  end

  def hiring_manager?
    name == "hiring_manager" && system_role?
  end

  def interviewer?
    name == "interviewer" && system_role?
  end
end
