# frozen_string_literal: true

module Admin
  class RolesController < BaseController
    before_action :set_role, only: [:show, :assign_user, :remove_user]

    def index
      @roles = current_organization.roles.includes(:users).order(:name)
    end

    def show
      @users = @role.users.order(:last_name, :first_name)
      @available_users = current_organization.users
                                             .where.not(id: @role.user_ids)
                                             .where(active: true)
                                             .order(:last_name, :first_name)
    end

    def assign_user
      user = current_organization.users.find(params[:user_id])

      unless user.roles.include?(@role)
        user.roles << @role
        flash[:notice] = "#{user.display_name} has been assigned the #{@role.name} role."
      end

      redirect_to admin_role_path(@role)
    end

    def remove_user
      user = current_organization.users.find(params[:user_id])

      if user == current_user && @role.name == "admin"
        flash[:alert] = "You cannot remove your own admin role."
      else
        user.user_roles.find_by(role: @role)&.destroy
        flash[:notice] = "#{user.display_name} has been removed from the #{@role.name} role."
      end

      redirect_to admin_role_path(@role)
    end

    private

    def set_role
      @role = current_organization.roles.find(params[:id])
    end

    def current_organization
      current_user.organization
    end
  end
end
