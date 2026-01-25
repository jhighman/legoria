# frozen_string_literal: true

class EeocResponsesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  before_action :set_application_from_token, only: [:new, :create]
  before_action :set_eeoc_response, only: [:show]

  def index
    # Admin view - EEOC data is anonymized for reporting
    authorize EeocResponse
    @responses = policy_scope(EeocResponse).includes(:application)
  end

  def show
    authorize @eeoc_response
  end

  def new
    @eeoc_response = @application.build_eeoc_response(organization: @application.organization)
    # Skip authorization for public form
  end

  def create
    @eeoc_response = @application.build_eeoc_response(
      organization: @application.organization,
      **eeoc_response_params,
      collection_context: "application",
      consent_given: params[:consent] == "1",
      consent_timestamp: Time.current,
      consent_ip_address: request.remote_ip
    )

    if @eeoc_response.save
      redirect_to career_application_status_path(token: @application.tracking_token),
                  notice: "Thank you for providing this information."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_application_from_token
    @application = Application.find_by!(tracking_token: params[:token])
  end

  def set_eeoc_response
    @eeoc_response = Current.organization.eeoc_responses.find(params[:id])
  end

  def eeoc_response_params
    params.require(:eeoc_response).permit(
      :gender, :race_ethnicity, :veteran_status, :disability_status
    )
  end
end
