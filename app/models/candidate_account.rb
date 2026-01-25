# frozen_string_literal: true

class CandidateAccount < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :lockable, :confirmable

  # Associations
  belongs_to :candidate

  # Delegations
  delegate :full_name, :first_name, :last_name, :phone, :applications, to: :candidate
  delegate :organization, to: :candidate, allow_nil: true

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # Callbacks
  before_validation :sync_email_with_candidate, on: :create

  # Scopes
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :with_job_alerts, -> { where(job_alerts: true) }

  # Override Devise to not require confirmation in development/test
  def confirmation_required?
    Rails.env.production?
  end

  # Account status
  def confirmed?
    confirmed_at.present?
  end

  def locked?
    locked_at.present?
  end

  # Job alerts
  def enable_job_alerts!(criteria = {})
    update!(job_alerts: true, job_alert_criteria: criteria)
  end

  def disable_job_alerts!
    update!(job_alerts: false, job_alert_criteria: nil)
  end

  def matching_jobs
    return Job.none unless job_alerts? && job_alert_criteria.present?

    scope = Job.kept.open

    criteria = job_alert_criteria.with_indifferent_access

    if criteria[:departments].present?
      scope = scope.where(department_id: criteria[:departments])
    end

    if criteria[:locations].present?
      scope = scope.where(location: criteria[:locations])
    end

    if criteria[:employment_types].present?
      scope = scope.where(employment_type: criteria[:employment_types])
    end

    if criteria[:keywords].present?
      keywords = criteria[:keywords]
      scope = scope.where("title LIKE ? OR description LIKE ?", "%#{keywords}%", "%#{keywords}%")
    end

    scope
  end

  # Display helpers
  def display_name
    candidate.full_name
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
  end

  private

  def sync_email_with_candidate
    self.email ||= candidate&.email
  end
end
