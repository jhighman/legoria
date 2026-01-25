# frozen_string_literal: true

class DeletionRequestsController < ApplicationController
  before_action :set_deletion_request, only: [:show, :verify, :process_request, :reject, :place_hold, :remove_hold]

  def index
    @deletion_requests = policy_scope(DeletionRequest).includes(:candidate, :processed_by)
    @deletion_requests = @deletion_requests.where(status: params[:status]) if params[:status].present?
    @deletion_requests = @deletion_requests.order(requested_at: :desc)
  end

  def show
    authorize @deletion_request
  end

  def new
    @candidate = Current.organization.candidates.find(params[:candidate_id])
    @deletion_request = @candidate.deletion_requests.build(organization: Current.organization)
    authorize @deletion_request
  end

  def create
    @candidate = Current.organization.candidates.find(params[:candidate_id])
    @deletion_request = @candidate.deletion_requests.build(
      organization: Current.organization,
      request_source: deletion_request_params[:request_source]
    )
    authorize @deletion_request

    if @deletion_request.save
      redirect_to @deletion_request, notice: "Deletion request created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def verify
    authorize @deletion_request

    @deletion_request.verify_identity!(params[:verification_method])
    redirect_to @deletion_request, notice: "Identity verified."
  rescue StandardError => e
    redirect_to @deletion_request, alert: e.message
  end

  def process_request
    authorize @deletion_request

    result = ProcessDeletionRequestService.call(
      deletion_request: @deletion_request,
      processed_by: current_user
    )

    if result.success?
      redirect_to @deletion_request, notice: "Deletion request processed successfully."
    else
      redirect_to @deletion_request, alert: result.failure[:errors].join(", ")
    end
  end

  def reject
    authorize @deletion_request

    @deletion_request.reject!(params[:rejection_reason], current_user)
    redirect_to @deletion_request, notice: "Deletion request rejected."
  rescue StandardError => e
    redirect_to @deletion_request, alert: e.message
  end

  def place_hold
    authorize @deletion_request

    @deletion_request.place_legal_hold!(params[:reason])
    redirect_to @deletion_request, notice: "Legal hold placed."
  rescue StandardError => e
    redirect_to @deletion_request, alert: e.message
  end

  def remove_hold
    authorize @deletion_request

    @deletion_request.remove_legal_hold!
    redirect_to @deletion_request, notice: "Legal hold removed."
  rescue StandardError => e
    redirect_to @deletion_request, alert: e.message
  end

  private

  def set_deletion_request
    @deletion_request = Current.organization.deletion_requests.find(params[:id])
  end

  def deletion_request_params
    params.require(:deletion_request).permit(:request_source)
  end
end
