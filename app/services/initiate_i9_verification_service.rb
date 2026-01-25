# frozen_string_literal: true

class InitiateI9VerificationService < ApplicationService
  # Initiates I-9 verification for an application after offer acceptance
  #
  # @example
  #   result = InitiateI9VerificationService.call(
  #     application: application,
  #     expected_start_date: Date.current + 14.days
  #   )
  #
  #   if result.success?
  #     verification = result.value!
  #     # Handle success
  #   else
  #     error = result.failure
  #     # Handle failure
  #   end

  option :application
  option :expected_start_date

  def call
    yield validate_application
    yield validate_no_existing_verification
    verification = yield create_verification
    yield update_application
    yield schedule_notifications(verification)

    Success(verification)
  end

  private

  def validate_application
    return Failure(:application_not_found) if application.nil?
    return Failure(:application_not_offered) unless application.status == "offered"
    return Failure(:i9_not_required) unless application.i9_required?

    Success(application)
  end

  def validate_no_existing_verification
    if application.i9_verification.present?
      return Failure(:i9_verification_exists)
    end

    Success(true)
  end

  def create_verification
    verification = I9Verification.new(
      organization: Current.organization,
      application: application,
      candidate: application.candidate,
      employee_start_date: expected_start_date,
      deadline_section1: expected_start_date,
      deadline_section2: calculate_section2_deadline(expected_start_date)
    )

    if verification.save
      Success(verification)
    else
      Failure(verification.errors.full_messages)
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors.full_messages)
  end

  def update_application
    if application.update(
      expected_start_date: expected_start_date,
      i9_status: "pending_section1"
    )
      Success(application)
    else
      Failure(application.errors.full_messages)
    end
  end

  def schedule_notifications(verification)
    # Queue notification job to send Section 1 request to candidate
    I9NotificationJob.perform_later(
      application.id,
      "section1_request"
    )

    Success(verification)
  end

  def calculate_section2_deadline(start_date)
    current = start_date
    3.times do
      current += 1.day
      current += 1.day while current.saturday? || current.sunday?
    end
    current
  end
end
