# frozen_string_literal: true

class GdprConsentsController < ApplicationController
  before_action :set_candidate
  before_action :set_gdpr_consent, only: [:show, :withdraw]

  def index
    @gdpr_consents = @candidate.gdpr_consents.order(created_at: :desc)
    authorize @gdpr_consents
  end

  def show
    authorize @gdpr_consent
  end

  def new
    @gdpr_consent = @candidate.gdpr_consents.build(organization: Current.organization)
    authorize @gdpr_consent
  end

  def create
    @gdpr_consent = @candidate.gdpr_consents.build(
      organization: Current.organization,
      **gdpr_consent_params
    )
    authorize @gdpr_consent

    if params[:grant] == "1"
      @gdpr_consent.grant!(
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        method: "application_form"
      )
    end

    if @gdpr_consent.save
      redirect_to candidate_path(@candidate), notice: "Consent recorded."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def withdraw
    authorize @gdpr_consent

    @gdpr_consent.withdraw!
    redirect_to candidate_gdpr_consents_path(@candidate), notice: "Consent withdrawn."
  end

  private

  def set_candidate
    @candidate = Current.organization.candidates.find(params[:candidate_id])
  end

  def set_gdpr_consent
    @gdpr_consent = @candidate.gdpr_consents.find(params[:id])
  end

  def gdpr_consent_params
    params.require(:gdpr_consent).permit(:consent_type, :consent_text, :consent_version)
  end
end
