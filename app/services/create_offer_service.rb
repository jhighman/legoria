# frozen_string_literal: true

class CreateOfferService < ApplicationService
  option :application
  option :created_by
  option :params
  option :template, default: -> { nil }

  def call
    yield validate_application
    offer = yield create_offer
    yield render_template(offer) if template
    yield create_approvals(offer) if params[:approvers].present?
    Success(offer)
  end

  private

  def validate_application
    unless application.active?
      return Failure(errors: ["Application is no longer active"])
    end

    # Check for existing pending/active offers
    if application.offers.active.exists?
      return Failure(errors: ["An active offer already exists for this application"])
    end

    Success()
  end

  def create_offer
    offer = Offer.new(
      organization: application.organization,
      application: application,
      offer_template: template,
      created_by: created_by,
      title: params[:title] || application.job.title,
      salary: params[:salary],
      salary_period: params[:salary_period] || "yearly",
      currency: params[:currency] || "USD",
      signing_bonus: params[:signing_bonus],
      annual_bonus_target: params[:annual_bonus_target],
      equity_type: params[:equity_type],
      equity_shares: params[:equity_shares],
      equity_vesting_schedule: params[:equity_vesting_schedule],
      employment_type: params[:employment_type],
      proposed_start_date: params[:proposed_start_date],
      work_location: params[:work_location],
      reports_to: params[:reports_to],
      department: params[:department] || application.job.department&.name,
      custom_terms: params[:custom_terms],
      expires_at: params[:expires_at]
    )

    if offer.save
      Success(offer)
    else
      Failure(errors: offer.errors.full_messages)
    end
  end

  def render_template(offer)
    offer.render_from_template!
    offer.save!
    Success()
  rescue StandardError => e
    Failure(errors: ["Failed to render template: #{e.message}"])
  end

  def create_approvals(offer)
    params[:approvers].each_with_index do |approver_id, index|
      offer.offer_approvals.create!(
        approver_id: approver_id,
        sequence: index + 1,
        requested_at: Time.current
      )
    end

    Success()
  rescue StandardError => e
    Failure(errors: ["Failed to create approvals: #{e.message}"])
  end
end
