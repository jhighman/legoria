# frozen_string_literal: true

class SendFinalAdverseActionService < ApplicationService
  option :adverse_action
  option :content
  option :delivery_method, default: -> { "email" }

  def call
    yield validate_adverse_action
    yield send_final_notice
    yield notify_candidate
    yield complete_adverse_action
    Success(adverse_action)
  end

  private

  def validate_adverse_action
    unless adverse_action.can_send_final?
      return Failure(errors: ["Cannot send final notice - waiting period has not elapsed"])
    end

    unless adverse_action.candidate.email.present?
      return Failure(errors: ["Candidate does not have an email address"])
    end

    Success()
  end

  def send_final_notice
    adverse_action.send_final_adverse!(
      content: content,
      delivery_method: delivery_method
    )
    Success()
  rescue StandardError => e
    Failure(errors: [e.message])
  end

  def notify_candidate
    # TODO: Send email to candidate with final adverse action notice
    # AdverseActionMailer.final_adverse_notice(adverse_action).deliver_later
    Success()
  end

  def complete_adverse_action
    adverse_action.complete!
    Success()
  rescue StandardError => e
    Failure(errors: [e.message])
  end
end
