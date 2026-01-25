# frozen_string_literal: true

class ApproveHiringDecisionService < ApplicationService
  # Approve or reject a pending hiring decision
  #
  # @example Approve
  #   result = ApproveHiringDecisionService.call(
  #     hiring_decision: decision,
  #     approved_by: current_user,
  #     action: :approve
  #   )
  #
  # @example Reject
  #   result = ApproveHiringDecisionService.call(
  #     hiring_decision: decision,
  #     approved_by: current_user,
  #     action: :reject,
  #     reason: "Need more interview feedback"
  #   )

  option :hiring_decision
  option :approved_by
  option :action # :approve or :reject
  option :reason, default: -> { nil }
  option :notify_team, default: -> { true }

  def call
    yield validate_decision
    yield validate_approver
    yield validate_action

    yield perform_action
    yield send_notifications if notify_team

    Success(hiring_decision)
  end

  private

  def validate_decision
    return Failure(:decision_not_found) if hiring_decision.nil?
    return Failure(:decision_not_pending) unless hiring_decision.pending?

    Success(hiring_decision)
  end

  def validate_approver
    return Failure(:approver_not_found) if approved_by.nil?

    # Check if user has permission to approve decisions
    unless can_approve?
      return Failure(:not_authorized_to_approve)
    end

    Success(approved_by)
  end

  def validate_action
    unless action.to_sym.in?([:approve, :reject])
      return Failure(:invalid_action)
    end

    # Require reason for rejection
    if action.to_sym == :reject && reason.blank?
      return Failure(:reason_required_for_rejection)
    end

    Success(action)
  end

  def perform_action
    case action.to_sym
    when :approve
      approve_decision
    when :reject
      reject_decision
    end
  end

  def approve_decision
    hiring_decision.approve!(approved_by: approved_by)
    Success(hiring_decision)
  rescue StandardError => e
    Failure("Failed to approve decision: #{e.message}")
  end

  def reject_decision
    hiring_decision.reject_approval!(rejected_by: approved_by, reason: reason)
    Success(hiring_decision)
  rescue StandardError => e
    Failure("Failed to reject decision: #{e.message}")
  end

  def send_notifications
    # Notify the original decision maker
    if action.to_sym == :approve
      HiringDecisionMailer.decision_approved(hiring_decision).deliver_later

      # If hire, notify candidate
      if hiring_decision.hire?
        # Could trigger offer letter workflow here
        # OfferLetterService.call(hiring_decision: hiring_decision)
      end
    else
      HiringDecisionMailer.decision_rejected(hiring_decision, reason).deliver_later
    end

    Success(true)
  rescue StandardError => e
    Rails.logger.error("Failed to send decision notifications: #{e.message}")
    Success(true)
  end

  def can_approve?
    # Approver must be admin, hiring manager, or senior recruiter
    # And cannot approve their own decisions
    return false if approved_by.id == hiring_decision.decided_by_id

    approved_by.admin? ||
      hiring_decision.job.hiring_manager_id == approved_by.id ||
      (approved_by.recruiter? && senior_recruiter?)
  end

  def senior_recruiter?
    # Check if user has senior recruiter role
    # This could be based on role or permission
    approved_by.roles.any? { |r| r.name.downcase.include?("senior") }
  rescue StandardError
    false
  end
end
