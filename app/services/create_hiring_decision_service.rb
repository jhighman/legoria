# frozen_string_literal: true

class CreateHiringDecisionService < ApplicationService
  # Create a hiring decision for an application
  #
  # @example
  #   result = CreateHiringDecisionService.call(
  #     application: application,
  #     decided_by: current_user,
  #     decision: "hire",
  #     rationale: "Strong candidate...",
  #     proposed_salary: 100000,
  #     proposed_start_date: 2.weeks.from_now
  #   )

  option :application
  option :decided_by
  option :decision
  option :rationale
  option :proposed_salary, default: -> { nil }
  option :proposed_salary_currency, default: -> { "USD" }
  option :proposed_start_date, default: -> { nil }
  option :require_approval, default: -> { true }
  option :notify_team, default: -> { true }

  def call
    yield validate_application
    yield validate_decision_maker
    yield validate_no_pending_decision

    hiring_decision = yield create_decision
    yield notify_for_approval(hiring_decision) if require_approval && notify_team

    Success(hiring_decision)
  end

  private

  def validate_application
    return Failure(:application_not_found) if application.nil?
    return Failure(:application_not_active) unless application.active?

    # Check if application is in appropriate stage for decision
    unless application.can_receive_decision?
      return Failure(:application_not_ready_for_decision)
    end

    Success(application)
  end

  def validate_decision_maker
    return Failure(:user_not_found) if decided_by.nil?

    # Check if user has permission to make hiring decisions
    # This could be more sophisticated with Pundit
    unless can_make_decision?
      return Failure(:not_authorized_to_decide)
    end

    Success(decided_by)
  end

  def validate_no_pending_decision
    if HiringDecision.where(application_id: application.id, status: "pending").exists?
      return Failure(:pending_decision_exists)
    end

    Success(true)
  end

  def create_decision
    hiring_decision = HiringDecision.new(
      organization: Current.organization,
      application: application,
      decided_by: decided_by,
      decision: decision,
      rationale: rationale,
      proposed_salary: proposed_salary,
      proposed_salary_currency: proposed_salary_currency,
      proposed_start_date: proposed_start_date,
      status: require_approval ? "pending" : "approved",
      decided_at: Time.current
    )

    # If not requiring approval, set approved_by to decided_by
    hiring_decision.approved_by = decided_by unless require_approval

    if hiring_decision.save
      Success(hiring_decision)
    else
      Failure(hiring_decision.errors.full_messages.join(", "))
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors.full_messages.join(", "))
  end

  def notify_for_approval(hiring_decision)
    # Find approvers (e.g., hiring manager, senior recruiter)
    approvers = find_approvers

    approvers.each do |approver|
      HiringDecisionMailer.approval_requested(hiring_decision, approver).deliver_later
    end

    Success(true)
  rescue StandardError => e
    Rails.logger.error("Failed to send approval notifications: #{e.message}")
    Success(true) # Don't fail the decision for notification errors
  end

  def can_make_decision?
    # User must be recruiter, hiring manager, or admin
    decided_by.admin? ||
      decided_by.recruiter? ||
      application.job.hiring_manager_id == decided_by.id
  end

  def find_approvers
    approvers = []

    # Add hiring manager if not the decider
    if application.job.hiring_manager.present? && application.job.hiring_manager != decided_by
      approvers << application.job.hiring_manager
    end

    # Add job owner if not the decider and different from hiring manager
    if application.job.owner.present? &&
       application.job.owner != decided_by &&
       application.job.owner != application.job.hiring_manager
      approvers << application.job.owner
    end

    approvers.compact.uniq
  end
end
