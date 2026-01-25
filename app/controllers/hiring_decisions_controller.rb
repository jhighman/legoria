# frozen_string_literal: true

class HiringDecisionsController < ApplicationController
  before_action :set_application, only: [:new, :create]
  before_action :set_hiring_decision, only: [:show, :approve, :reject_approval]

  def index
    @hiring_decisions = policy_scope(HiringDecision)
                         .includes(:application, :decided_by, :approved_by, application: [:candidate, :job])
                         .then { |q| params[:status].present? ? q.where(status: params[:status]) : q }
                         .then { |q| params[:decision].present? ? q.where(decision: params[:decision]) : q }
                         .recent
                         .page(params[:page])
  end

  def show
    authorize @hiring_decision
  end

  def new
    @hiring_decision = @application.hiring_decisions.build
    authorize @hiring_decision
  end

  def create
    authorize HiringDecision

    result = CreateHiringDecisionService.call(
      application: @application,
      decided_by: current_user,
      decision: hiring_decision_params[:decision],
      rationale: hiring_decision_params[:rationale],
      proposed_salary: hiring_decision_params[:proposed_salary],
      proposed_salary_currency: hiring_decision_params[:proposed_salary_currency],
      proposed_start_date: hiring_decision_params[:proposed_start_date],
      require_approval: hiring_decision_params[:require_approval] != "false"
    )

    if result.success?
      redirect_to application_path(@application), notice: "Hiring decision was created successfully."
    else
      @hiring_decision = @application.hiring_decisions.build(hiring_decision_params)
      flash.now[:alert] = result.failure.to_s
      render :new, status: :unprocessable_entity
    end
  end

  def approve
    authorize @hiring_decision

    result = ApproveHiringDecisionService.call(
      hiring_decision: @hiring_decision,
      approved_by: current_user,
      action: :approve
    )

    if result.success?
      redirect_to hiring_decision_path(@hiring_decision), notice: "Hiring decision was approved."
    else
      redirect_to hiring_decision_path(@hiring_decision), alert: result.failure.to_s
    end
  end

  def reject_approval
    authorize @hiring_decision, :approve?

    result = ApproveHiringDecisionService.call(
      hiring_decision: @hiring_decision,
      approved_by: current_user,
      action: :reject,
      reason: params[:reason]
    )

    if result.success?
      redirect_to hiring_decision_path(@hiring_decision), notice: "Hiring decision was rejected."
    else
      redirect_to hiring_decision_path(@hiring_decision), alert: result.failure.to_s
    end
  end

  private

  def set_application
    @application = Application.find(params[:application_id])
  end

  def set_hiring_decision
    @hiring_decision = HiringDecision.find(params[:id])
  end

  def hiring_decision_params
    params.require(:hiring_decision).permit(
      :decision,
      :rationale,
      :proposed_salary,
      :proposed_salary_currency,
      :proposed_start_date,
      :require_approval
    )
  end
end
