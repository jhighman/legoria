# frozen_string_literal: true

class JobApproval < ApplicationRecord
  # Statuses
  STATUSES = %w[pending approved rejected].freeze

  # Associations
  belongs_to :job
  belongs_to :approver, class_name: "User"

  # Delegate organization_id to job for consistency
  delegate :organization_id, to: :job

  # Validations
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :sequence, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Scopes
  scope :pending, -> { where(status: :pending) }
  scope :approved, -> { where(status: :approved) }
  scope :rejected, -> { where(status: :rejected) }
  scope :decided, -> { where.not(status: :pending) }
  scope :by_sequence, -> { order(sequence: :asc) }

  # Status helpers
  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  def decided?
    !pending?
  end

  # Actions
  def approve!(notes: nil)
    return false unless pending?

    update!(
      status: :approved,
      notes: notes,
      decided_at: Time.current
    )

    job.approve if job.can_approve?
    true
  end

  def reject!(notes: nil)
    return false unless pending?

    update!(
      status: :rejected,
      notes: notes,
      decided_at: Time.current
    )

    job.reject if job.can_reject?
    true
  end
end
