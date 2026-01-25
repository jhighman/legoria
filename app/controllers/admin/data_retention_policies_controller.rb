# frozen_string_literal: true

module Admin
  class DataRetentionPoliciesController < ApplicationController
    before_action :set_policy, only: [:show, :edit, :update, :destroy, :toggle_active]

    def index
      @policies = policy_scope(DataRetentionPolicy).order(:data_category)
    end

    def show
      authorize @policy
    end

    def new
      @policy = Current.organization.data_retention_policies.build
      authorize @policy
    end

    def create
      @policy = Current.organization.data_retention_policies.build(policy_params)
      authorize @policy

      if @policy.save
        redirect_to admin_data_retention_policy_path(@policy), notice: "Data retention policy created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @policy
    end

    def update
      authorize @policy

      if @policy.update(policy_params)
        redirect_to admin_data_retention_policy_path(@policy), notice: "Data retention policy updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @policy

      @policy.destroy
      redirect_to admin_data_retention_policies_path, notice: "Data retention policy deleted."
    end

    def toggle_active
      authorize @policy

      if @policy.active?
        @policy.deactivate!
        redirect_to admin_data_retention_policies_path, notice: "Policy deactivated."
      else
        @policy.activate!
        redirect_to admin_data_retention_policies_path, notice: "Policy activated."
      end
    rescue StandardError => e
      redirect_to admin_data_retention_policies_path, alert: e.message
    end

    private

    def set_policy
      @policy = Current.organization.data_retention_policies.find(params[:id])
    end

    def policy_params
      params.require(:data_retention_policy).permit(
        :name, :description, :data_category, :retention_days,
        :retention_trigger, :action_type, :notify_candidate, :active
      )
    end
  end
end
