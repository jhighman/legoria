# frozen_string_literal: true

module Admin
  class OfferTemplatesController < ApplicationController
    before_action :set_offer_template, only: [:show, :edit, :update, :destroy, :duplicate, :make_default]

    def index
      @offer_templates = policy_scope(OfferTemplate).order(:template_type, :name)
    end

    def show
      authorize @offer_template
    end

    def new
      @offer_template = Current.organization.offer_templates.build
      authorize @offer_template
    end

    def create
      @offer_template = Current.organization.offer_templates.build(offer_template_params)
      authorize @offer_template

      if @offer_template.save
        redirect_to admin_offer_template_path(@offer_template), notice: "Offer template created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @offer_template
    end

    def update
      authorize @offer_template

      if @offer_template.update(offer_template_params)
        redirect_to admin_offer_template_path(@offer_template), notice: "Offer template updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @offer_template

      if @offer_template.offers.none?
        @offer_template.destroy
        redirect_to admin_offer_templates_path, notice: "Offer template deleted."
      else
        redirect_to admin_offer_template_path(@offer_template), alert: "Cannot delete template with associated offers."
      end
    end

    def duplicate
      authorize @offer_template

      new_template = @offer_template.duplicate
      new_template.save!
      redirect_to edit_admin_offer_template_path(new_template), notice: "Template duplicated."
    end

    def make_default
      authorize @offer_template

      @offer_template.make_default!
      redirect_to admin_offer_template_path(@offer_template), notice: "Template set as default."
    end

    private

    def set_offer_template
      @offer_template = Current.organization.offer_templates.find(params[:id])
    end

    def offer_template_params
      params.require(:offer_template).permit(
        :name, :description, :template_type, :subject_line, :body, :footer, :active
      )
    end
  end
end
