# frozen_string_literal: true

class InterviewParticipant < ApplicationRecord
  # Roles
  ROLES = %w[lead interviewer shadow note_taker].freeze

  # Status constants
  STATUSES = %w[pending accepted declined tentative].freeze

  # Associations
  belongs_to :interview
  belongs_to :user

  has_one :scorecard, dependent: :nullify

  # Delegations for convenience
  delegate :organization, to: :interview
  delegate :application, to: :interview
  delegate :scheduled_at, to: :interview

  # Validations
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :interview_id, message: "is already a participant" }

  validate :user_in_same_organization

  # Scopes
  scope :leads, -> { where(role: "lead") }
  scope :interviewers, -> { where(role: %w[lead interviewer]) }
  scope :shadows, -> { where(role: "shadow") }
  scope :note_takers, -> { where(role: "note_taker") }

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :declined, -> { where(status: "declined") }

  scope :with_feedback, -> { where(feedback_submitted: true) }
  scope :without_feedback, -> { where(feedback_submitted: false) }
  scope :needs_feedback, -> { interviewers.without_feedback }

  scope :for_upcoming_interviews, -> {
    joins(:interview)
      .where(interviews: { status: Interview::ACTIVE_STATUSES })
      .where("interviews.scheduled_at > ?", Time.current)
  }

  # Role helpers
  def lead?
    role == "lead"
  end

  def interviewer?
    role.in?(%w[lead interviewer])
  end

  def shadow?
    role == "shadow"
  end

  def note_taker?
    role == "note_taker"
  end

  def requires_feedback?
    interviewer? && !shadow? && !note_taker?
  end

  # Status helpers
  def pending?
    status == "pending"
  end

  def accepted?
    status == "accepted"
  end

  def declined?
    status == "declined"
  end

  def tentative?
    status == "tentative"
  end

  # Response methods
  def accept!
    update!(status: "accepted", responded_at: Time.current)
  end

  def decline!
    update!(status: "declined", responded_at: Time.current)
  end

  def mark_tentative!
    update!(status: "tentative", responded_at: Time.current)
  end

  # Feedback methods
  def submit_feedback!
    update!(feedback_submitted: true, feedback_submitted_at: Time.current)
  end

  def feedback_overdue?(days: 2)
    return false unless requires_feedback?
    return false if feedback_submitted?
    return false unless interview.completed?

    interview.completed_at.present? && interview.completed_at < days.days.ago
  end

  # Display helpers
  def role_label
    role.titleize.gsub("_", " ")
  end

  def status_label
    status.titleize
  end

  def status_color
    case status
    when "pending" then "yellow"
    when "accepted" then "green"
    when "declined" then "red"
    when "tentative" then "blue"
    else "gray"
    end
  end

  private

  def user_in_same_organization
    return if interview.blank? || user.blank?

    errors.add(:user, "must be in the same organization") unless user.organization_id == interview.organization_id
  end
end
