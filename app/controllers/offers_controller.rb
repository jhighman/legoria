# frozen_string_literal: true

class OffersController < ApplicationController
  before_action :set_offer, only: [:show, :edit, :update, :destroy, :submit_for_approval, :send_offer, :withdraw]

  def index
    @offers = policy_scope(Offer).includes(:application, :created_by, :offer_template)
    @offers = @offers.by_status(params[:status]) if params[:status].present?
    @offers = @offers.order(created_at: :desc)
  end

  def show
    authorize @offer
  end

  def new
    @application = Current.organization.applications.find(params[:application_id])
    @offer = @application.offers.build
    authorize @offer
    @templates = Current.organization.offer_templates.active
  end

  def create
    @application = Current.organization.applications.find(params[:application_id])
    @offer = @application.offers.build
    authorize @offer

    template = params[:offer_template_id].present? ? Current.organization.offer_templates.find(params[:offer_template_id]) : nil

    result = CreateOfferService.call(
      application: @application,
      created_by: current_user,
      params: offer_params,
      template: template
    )

    if result.success?
      redirect_to result.value!, notice: "Offer created successfully."
    else
      @templates = Current.organization.offer_templates.active
      flash.now[:alert] = result.failure[:errors].join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @offer
    @templates = Current.organization.offer_templates.active
  end

  def update
    authorize @offer

    if @offer.can_edit? && @offer.update(offer_params)
      redirect_to @offer, notice: "Offer updated successfully."
    else
      @templates = Current.organization.offer_templates.active
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @offer

    if @offer.draft?
      @offer.destroy
      redirect_to offers_path, notice: "Offer deleted."
    else
      redirect_to @offer, alert: "Cannot delete offer that is not in draft status."
    end
  end

  def submit_for_approval
    authorize @offer

    if @offer.submit_for_approval!
      redirect_to @offer, notice: "Offer submitted for approval."
    else
      redirect_to @offer, alert: "Could not submit offer for approval."
    end
  rescue StandardError => e
    redirect_to @offer, alert: e.message
  end

  def send_offer
    authorize @offer

    result = SendOfferService.call(offer: @offer, sent_by: current_user)

    if result.success?
      redirect_to @offer, notice: "Offer sent to candidate."
    else
      redirect_to @offer, alert: result.failure[:errors].join(", ")
    end
  end

  def withdraw
    authorize @offer

    @offer.withdraw!
    redirect_to @offer, notice: "Offer withdrawn."
  rescue StandardError => e
    redirect_to @offer, alert: e.message
  end

  private

  def set_offer
    @offer = Current.organization.offers.find(params[:id])
  end

  def offer_params
    params.require(:offer).permit(
      :title, :salary, :salary_period, :currency, :signing_bonus,
      :annual_bonus_target, :equity_type, :equity_shares, :equity_vesting_schedule,
      :employment_type, :proposed_start_date, :work_location, :reports_to,
      :department, :custom_terms, :expires_at, approvers: []
    )
  end
end
