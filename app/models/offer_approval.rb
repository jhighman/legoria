# frozen_string_literal: true

class OfferApproval < ApplicationRecord
  # Status constants
  STATUSES = %w[pending approved rejected].freeze

  # Associations
  belongs_to :offer
  belongs_to :approver, class_name: "User"

  # Delegations
  delegate :organization, to: :offer
  delegate :candidate, :job, to: :offer

  # Validations
  validates :sequence, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :in_sequence, -> { order(sequence: :asc) }

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

  def responded?
    approved? || rejected?
  end

  # Actions
  def approve!(comment = nil)
    raise StandardError, "Already responded to this approval" if responded?

    transaction do
      update!(
        status: "approved",
        comments: comment,
        responded_at: Time.current
      )

      # Check if all approvals are complete
      check_offer_approval_status
    end
  end

  def reject!(comment = nil)
    raise StandardError, "Already responded to this approval" if responded?

    transaction do
      update!(
        status: "rejected",
        comments: comment,
        responded_at: Time.current
      )

      # Reject the offer
      offer.reject_approval!(comment)
    end
  end

  # Display helpers
  def status_label
    status.titleize
  end

  def status_color
    case status
    when "pending" then "yellow"
    when "approved" then "green"
    when "rejected" then "red"
    else "gray"
    end
  end

  def waiting_time
    return nil unless pending?

    time_diff = Time.current - (requested_at || created_at)
    days = (time_diff / 1.day).floor
    hours = ((time_diff % 1.day) / 1.hour).floor

    if days > 0
      "#{days}d #{hours}h"
    else
      "#{hours}h"
    end
  end

  private

  def check_offer_approval_status
    return unless offer.offer_approvals.pending.none?

    # All approvals are complete - approve the offer
    offer.approve! if offer.offer_approvals.rejected.none?
  end
end
