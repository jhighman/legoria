# frozen_string_literal: true

class MoveStageService < ApplicationService
  # Move an application to a new stage
  #
  # @example
  #   result = MoveStageService.call(
  #     application: application,
  #     to_stage: new_stage,
  #     moved_by: current_user,
  #     notes: "Ready for interview"
  #   )
  #
  #   if result.success?
  #     transition = result.value!
  #     # Handle success
  #   else
  #     error = result.failure
  #     # Handle failure
  #   end

  option :application
  option :to_stage
  option :moved_by, optional: true
  option :notes, optional: true

  def call
    yield validate_application
    yield validate_stage
    yield validate_transition

    transition = yield create_transition
    yield update_application

    Success(transition)
  end

  private

  def validate_application
    return Failure(:application_not_found) if application.nil?
    return Failure(:application_not_active) unless application.active?
    return Failure(:application_discarded) if application.discarded?

    Success(application)
  end

  def validate_stage
    return Failure(:stage_not_found) if to_stage.nil?
    return Failure(:stage_wrong_organization) if to_stage.organization_id != application.organization_id

    Success(to_stage)
  end

  def validate_transition
    # Can't move to the same stage
    if application.current_stage_id == to_stage.id
      return Failure(:same_stage)
    end

    # Check if this is a valid stage progression for the job
    job_stages = application.job.job_stages.pluck(:stage_id)
    unless job_stages.include?(to_stage.id)
      return Failure(:stage_not_in_job)
    end

    Success(true)
  end

  def create_transition
    transition = StageTransition.new(
      application: application,
      from_stage: application.current_stage,
      to_stage: to_stage,
      moved_by: moved_by,
      notes: notes
    )

    if transition.save
      Success(transition)
    else
      Failure(transition.errors.full_messages)
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors.full_messages)
  end

  def update_application
    if application.update(current_stage: to_stage, last_activity_at: Time.current)
      Success(application)
    else
      Failure(application.errors.full_messages)
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors.full_messages)
  end
end
