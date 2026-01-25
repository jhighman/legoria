# frozen_string_literal: true

class InitiateAdverseActionService < ApplicationService
  option :application
  option :initiated_by
  option :action_type
  option :reason_category
  option :reason_details, default: -> { nil }
  option :background_check_provider, default: -> { nil }

  def call
    yield validate_application
    adverse_action = yield create_adverse_action
    Success(adverse_action)
  end

  private

  def validate_application
    unless application.active?
      return Failure(errors: ["Application is no longer active"])
    end

    # Check for existing active adverse actions
    if application.adverse_actions.active.exists?
      return Failure(errors: ["An adverse action is already in progress for this application"])
    end

    Success()
  end

  def create_adverse_action
    adverse_action = AdverseAction.new(
      organization: application.organization,
      application: application,
      initiated_by: initiated_by,
      action_type: action_type,
      reason_category: reason_category,
      reason_details: reason_details,
      background_check_provider: background_check_provider
    )

    if adverse_action.save
      Success(adverse_action)
    else
      Failure(errors: adverse_action.errors.full_messages)
    end
  end
end
