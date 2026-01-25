# frozen_string_literal: true

class CompleteI9Section1Service < ApplicationService
  # Completes Section 1 of I-9 verification (employee portion)
  #
  # @example
  #   result = CompleteI9Section1Service.call(
  #     i9_verification: verification,
  #     section1_params: {
  #       citizenship_status: "citizen",
  #       attestation_accepted: true
  #     },
  #     ip_address: request.remote_ip,
  #     user_agent: request.user_agent
  #   )

  option :i9_verification
  option :section1_params
  option :ip_address
  option :user_agent

  def call
    yield validate_status
    yield validate_attestation
    yield validate_citizenship_fields
    yield update_section1
    yield transition_status

    Success(i9_verification)
  end

  private

  def validate_status
    unless i9_verification.status == "pending_section1"
      return Failure(:invalid_status)
    end

    Success(true)
  end

  def validate_attestation
    unless section1_params[:attestation_accepted].to_s == "true" || section1_params[:attestation_accepted] == true
      return Failure(:attestation_required)
    end

    Success(true)
  end

  def validate_citizenship_fields
    citizenship = section1_params[:citizenship_status]

    unless citizenship.present?
      return Failure(:citizenship_required)
    end

    unless I9Verification::CITIZENSHIP_STATUSES.include?(citizenship)
      return Failure(:invalid_citizenship_status)
    end

    # Validate additional fields for non-citizens
    if citizenship == "alien_authorized"
      # Must have either USCIS number, I-94, or foreign passport
      has_valid_docs = section1_params[:alien_number].present? ||
                       section1_params[:i94_number].present? ||
                       section1_params[:foreign_passport_number].present?

      unless has_valid_docs
        return Failure(:alien_documentation_required)
      end
    end

    Success(true)
  end

  def update_section1
    attrs = section1_params.slice(
      :citizenship_status,
      :attestation_accepted,
      :alien_number,
      :alien_expiration_date,
      :i94_number,
      :foreign_passport_number,
      :foreign_passport_country
    ).merge(
      section1_completed_at: Time.current,
      section1_signature_ip: ip_address,
      section1_signature_user_agent: user_agent
    )

    if i9_verification.update(attrs)
      Success(i9_verification)
    else
      Failure(i9_verification.errors.full_messages)
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors.full_messages)
  end

  def transition_status
    i9_verification.complete_section1!

    # Send notification that Section 1 is complete
    I9NotificationJob.perform_later(
      i9_verification.application_id,
      "section1_complete"
    )

    Success(i9_verification)
  rescue StateMachines::InvalidTransition => e
    Failure(e.message)
  end
end
