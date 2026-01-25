# frozen_string_literal: true

class OfferApprovalsController < ApplicationController
  before_action :set_offer_approval

  def approve
    authorize @offer_approval

    @offer_approval.approve!(params[:comments])
    redirect_to @offer_approval.offer, notice: "Offer approved."
  rescue StandardError => e
    redirect_to @offer_approval.offer, alert: e.message
  end

  def reject
    authorize @offer_approval

    @offer_approval.reject!(params[:comments])
    redirect_to @offer_approval.offer, notice: "Offer rejected and returned to draft."
  rescue StandardError => e
    redirect_to @offer_approval.offer, alert: e.message
  end

  private

  def set_offer_approval
    @offer_approval = OfferApproval.find(params[:id])
  end
end
