# frozen_string_literal: true

class User < ApplicationRecord
  include OrganizationScoped
  include Auditable

  # Audit configuration
  audit_actions create: "user.created", update: "user.updated", destroy: "user.deactivated"
  audit_exclude :encrypted_password, :reset_password_token, :unlock_token

  # Devise modules
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable,
         :lockable,
         :confirmable

  # Associations
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :user_sessions, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :sso_identities, dependent: :destroy

  # Jobs associations
  has_many :managed_jobs, class_name: "Job", foreign_key: :hiring_manager_id, dependent: :nullify
  has_many :recruited_jobs, class_name: "Job", foreign_key: :recruiter_id, dependent: :nullify
  has_many :job_approvals, foreign_key: :approver_id, dependent: :nullify

  # Candidate associations
  has_many :referred_candidates, class_name: "Candidate", foreign_key: :referred_by_id, dependent: :nullify
  has_many :candidate_notes, dependent: :destroy

  # Activity associations
  has_many :stage_transitions_performed, class_name: "StageTransition", foreign_key: :moved_by_id, dependent: :nullify
  has_many :audit_logs, dependent: :nullify
  has_many :granted_user_roles, class_name: "UserRole", foreign_key: :granted_by_id, dependent: :nullify

  # Interview associations
  has_many :scheduled_interviews, class_name: "Interview", foreign_key: :scheduled_by_id, dependent: :nullify
  has_many :interview_participants, dependent: :destroy
  has_many :interviews_as_participant, through: :interview_participants, source: :interview
  has_one :calendar_integration, dependent: :destroy

  # Phase 5: Intelligence
  has_many :saved_searches, dependent: :destroy
  has_many :owned_talent_pools, class_name: "TalentPool", foreign_key: :owner_id, dependent: :destroy
  has_many :automation_rules, foreign_key: :created_by_id, dependent: :destroy

  # Validations
  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, presence: true, length: { maximum: 100 }
  validates :email, presence: true,
                    uniqueness: { scope: :organization_id, case_sensitive: false }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :locked, -> { where.not(locked_at: nil) }
  scope :with_role, ->(role_name) { joins(:roles).where(roles: { name: role_name }) }

  # Name helpers
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
  end

  def display_name
    full_name.presence || email
  end

  # Status helpers
  def active?
    active
  end

  def confirmed?
    confirmed_at.present?
  end

  def locked?
    locked_at.present?
  end

  # Role helpers
  def admin?
    has_role?("admin")
  end

  def recruiter?
    has_role?("recruiter")
  end

  def hiring_manager?
    has_role?("hiring_manager")
  end

  def interviewer?
    has_role?("interviewer")
  end

  def has_role?(role_name)
    roles.exists?(name: role_name)
  end

  def role_names
    roles.pluck(:name)
  end

  # Permission helpers
  def has_permission?(resource, action)
    roles.any? { |role| role.has_permission?(resource, action) }
  end

  def can?(action, resource)
    has_permission?(resource.to_s, action.to_s)
  end

  # Role assignment
  def assign_role(role, granted_by: nil)
    return if has_role?(role.is_a?(Role) ? role.name : role)

    role_record = role.is_a?(Role) ? role : organization.roles.find_by!(name: role)
    user_roles.create!(role: role_record, granted_by: granted_by)
  end

  def remove_role(role)
    role_name = role.is_a?(Role) ? role.name : role
    user_roles.joins(:role).where(roles: { name: role_name }).destroy_all
  end

  # Account management
  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end

  # Override Devise to check active status
  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :deactivated
  end

  protected

  # Override Devise method to allow authentication with unconfirmed email
  # in development (remove or modify for production)
  def confirmation_required?
    Rails.env.production?
  end
end
