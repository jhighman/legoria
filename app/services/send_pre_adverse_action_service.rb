# frozen_string_literal: true

class SendPreAdverseActionService < ApplicationService
  option :adverse_action
  option :content
  option :delivery_method, default: -> { "email" }

  def call
    yield validate_adverse_action
    yield send_pre_adverse_notice
    yield notify_candidate
    Success(adverse_action)
  end

  private

  def validate_adverse_action
    unless adverse_action.draft?
      return Failure(errors: ["Pre-adverse notice has already been sent"])
    end

    unless adverse_action.candidate.email.present?
      return Failure(errors: ["Candidate does not have an email address"])
    end

    Success()
  end

  def send_pre_adverse_notice
    adverse_action.send_pre_adverse!(
      content: content,
      delivery_method: delivery_method
    )
    Success()
  rescue StandardError => e
    Failure(errors: [e.message])
  end

  def notify_candidate
    # TODO: Send email to candidate with pre-adverse action notice
    # AdverseActionMailer.pre_adverse_notice(adverse_action).deliver_later
    Success()
  end
end
