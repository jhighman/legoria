# frozen_string_literal: true

module Admin
  class LookupValuesController < BaseController
    before_action :set_lookup_type
    before_action :set_lookup_value, only: [:edit, :update, :destroy, :move, :toggle_active]

    def new
      @lookup_value = @lookup_type.lookup_values.build
      @lookup_value.translations = { "en" => { "name" => "", "description" => "" } }
    end

    def create
      @lookup_value = @lookup_type.lookup_values.build(lookup_value_params)
      @lookup_value.position = (@lookup_type.lookup_values.maximum(:position) || 0) + 1

      if @lookup_value.save
        flash[:notice] = "Lookup value created successfully."
        redirect_to admin_lookup_type_path(@lookup_type)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @lookup_value.update(lookup_value_params)
        flash[:notice] = "Lookup value updated successfully."
        redirect_to admin_lookup_type_path(@lookup_type)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @lookup_value.destroy
      flash[:notice] = "Lookup value deleted successfully."
      redirect_to admin_lookup_type_path(@lookup_type)
    end

    def move
      direction = params[:direction]
      if direction == "up"
        move_up
      elsif direction == "down"
        move_down
      end
      redirect_to admin_lookup_type_path(@lookup_type)
    end

    def toggle_active
      @lookup_value.update(active: !@lookup_value.active?)
      status = @lookup_value.active? ? "activated" : "deactivated"
      flash[:notice] = "#{@lookup_value.name} has been #{status}."
      redirect_to admin_lookup_type_path(@lookup_type)
    end

    private

    def set_lookup_type
      @lookup_type = current_organization.lookup_types.find(params[:lookup_type_id])
    end

    def set_lookup_value
      @lookup_value = @lookup_type.lookup_values.find(params[:id])
    end

    def lookup_value_params
      permitted = params.require(:lookup_value).permit(:code, :is_default, :active, translations: {})

      # Process translations from form params
      if params[:lookup_value][:translations_en_name].present?
        permitted[:translations] = {
          "en" => {
            "name" => params[:lookup_value][:translations_en_name],
            "description" => params[:lookup_value][:translations_en_description]
          }.compact
        }
      end

      permitted
    end

    def current_organization
      current_user.organization
    end

    def move_up
      previous_value = @lookup_type.lookup_values
                                   .where("position < ?", @lookup_value.position)
                                   .order(position: :desc)
                                   .first
      return unless previous_value

      swap_positions(@lookup_value, previous_value)
    end

    def move_down
      next_value = @lookup_type.lookup_values
                               .where("position > ?", @lookup_value.position)
                               .order(position: :asc)
                               .first
      return unless next_value

      swap_positions(@lookup_value, next_value)
    end

    def swap_positions(value1, value2)
      pos1 = value1.position
      pos2 = value2.position
      value1.update_column(:position, pos2)
      value2.update_column(:position, pos1)
    end
  end
end
