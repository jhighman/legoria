# frozen_string_literal: true

class RejectApplicationService < ApplicationService
  # Reject an application with a reason and optional notes
  #
  # @example
  #   result = RejectApplicationService.call(
  #     application: application,
  #     rejection_reason: reason,
  #     rejected_by: current_user,
  #     notes: "Not enough experience"
  #   )

  option :application
  option :rejection_reason
  option :rejected_by, optional: true
  option :notes, optional: true

  def call
    yield validate_application
    yield validate_reason

    transition = yield create_rejection_transition
    yield update_application

    Success(transition)
  end

  private

  def validate_application
    return Failure(:application_not_found) if application.nil?
    return Failure(:application_not_active) unless application.active?
    return Failure(:cannot_reject) unless application.can_reject?

    Success(application)
  end

  def validate_reason
    return Failure(:reason_required) if rejection_reason.nil?

    unless rejection_reason.organization_id == application.organization_id
      return Failure(:reason_wrong_organization)
    end

    Success(rejection_reason)
  end

  def create_rejection_transition
    # Find or create a "Rejected" stage for the transition record
    rejected_stage = find_or_create_rejected_stage

    transition = StageTransition.new(
      application: application,
      from_stage: application.current_stage,
      to_stage: rejected_stage,
      moved_by: rejected_by,
      notes: build_rejection_notes
    )

    if transition.save
      Success(transition)
    else
      Failure(transition.errors.full_messages)
    end
  end

  def update_application
    application.rejection_reason = rejection_reason
    application.rejection_notes = notes

    if application.reject!
      # Send rejection notification email
      JobApplicationMailer.rejection_notice(application).deliver_later
      Success(application)
    else
      Failure(application.errors.full_messages)
    end
  rescue StateMachines::InvalidTransition => e
    Failure(e.message)
  end

  def find_or_create_rejected_stage
    Stage.find_or_create_by!(
      organization_id: application.organization_id,
      name: "Rejected",
      stage_type: "rejected"
    ) do |stage|
      stage.position = 999
      stage.is_terminal = true
      stage.color = "#EF4444"
    end
  end

  def build_rejection_notes
    parts = []
    parts << "Reason: #{rejection_reason.name}"
    parts << notes if notes.present?
    parts.join("\n")
  end
end
