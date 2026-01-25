# frozen_string_literal: true

module Admin
  class LookupTypesController < BaseController
    before_action :set_lookup_type, only: [:show, :edit, :update]

    def index
      @lookup_types = current_organization.lookup_types.includes(:lookup_values).ordered
    end

    def show
      @lookup_values = @lookup_type.lookup_values.ordered
    end

    def edit
    end

    def update
      if @lookup_type.update(lookup_type_params)
        flash[:notice] = "Lookup type updated successfully."
        redirect_to admin_lookup_type_path(@lookup_type)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_lookup_type
      @lookup_type = current_organization.lookup_types.find(params[:id])
    end

    def lookup_type_params
      params.require(:lookup_type).permit(:name, :description, :active)
    end

    def current_organization
      current_user.organization
    end
  end
end
