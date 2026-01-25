# frozen_string_literal: true

class AdverseActionsController < ApplicationController
  before_action :set_adverse_action, only: [:show, :edit, :update, :send_pre_adverse, :record_dispute, :send_final, :cancel]

  def index
    @adverse_actions = policy_scope(AdverseAction).includes(:application, :initiated_by)
    @adverse_actions = @adverse_actions.where(status: params[:status]) if params[:status].present?
    @adverse_actions = @adverse_actions.order(created_at: :desc)
  end

  def show
    authorize @adverse_action
  end

  def new
    @application = Current.organization.applications.find(params[:application_id])
    @adverse_action = @application.adverse_actions.build
    authorize @adverse_action
  end

  def create
    @application = Current.organization.applications.find(params[:application_id])
    @adverse_action = @application.adverse_actions.build
    authorize @adverse_action

    result = InitiateAdverseActionService.call(
      application: @application,
      initiated_by: current_user,
      action_type: adverse_action_params[:action_type],
      reason_category: adverse_action_params[:reason_category],
      reason_details: adverse_action_params[:reason_details],
      background_check_provider: adverse_action_params[:background_check_provider]
    )

    if result.success?
      redirect_to result.value!, notice: "Adverse action initiated."
    else
      flash.now[:alert] = result.failure[:errors].join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @adverse_action
  end

  def update
    authorize @adverse_action

    if @adverse_action.draft? && @adverse_action.update(adverse_action_params)
      redirect_to @adverse_action, notice: "Adverse action updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def send_pre_adverse
    authorize @adverse_action

    result = SendPreAdverseActionService.call(
      adverse_action: @adverse_action,
      content: params[:content],
      delivery_method: params[:delivery_method] || "email"
    )

    if result.success?
      redirect_to @adverse_action, notice: "Pre-adverse action notice sent. Waiting period started."
    else
      redirect_to @adverse_action, alert: result.failure[:errors].join(", ")
    end
  end

  def record_dispute
    authorize @adverse_action

    @adverse_action.record_dispute!(params[:dispute_details])
    redirect_to @adverse_action, notice: "Dispute recorded."
  rescue StandardError => e
    redirect_to @adverse_action, alert: e.message
  end

  def send_final
    authorize @adverse_action

    result = SendFinalAdverseActionService.call(
      adverse_action: @adverse_action,
      content: params[:content],
      delivery_method: params[:delivery_method] || "email"
    )

    if result.success?
      redirect_to @adverse_action, notice: "Final adverse action notice sent. Application rejected."
    else
      redirect_to @adverse_action, alert: result.failure[:errors].join(", ")
    end
  end

  def cancel
    authorize @adverse_action

    @adverse_action.cancel!(params[:reason])
    redirect_to @adverse_action, notice: "Adverse action cancelled."
  rescue StandardError => e
    redirect_to @adverse_action, alert: e.message
  end

  private

  def set_adverse_action
    @adverse_action = Current.organization.adverse_actions.find(params[:id])
  end

  def adverse_action_params
    params.require(:adverse_action).permit(
      :action_type, :reason_category, :reason_details, :background_check_provider,
      :waiting_period_days
    )
  end
end
