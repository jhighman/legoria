# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:show, :edit, :update, :activate, :deactivate]

    def index
      @users = current_organization.users
                                   .includes(:roles)
                                   .order(:last_name, :first_name)

      @users = @users.where("first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?
      @users = @users.joins(:roles).where(roles: { name: params[:role] }) if params[:role].present?
      @users = @users.where(active: params[:status] == "active") if params[:status].present?
    end

    def show
    end

    def new
      @user = current_organization.users.build
      @roles = current_organization.roles.order(:name)
    end

    def create
      @user = current_organization.users.build(user_params)
      @roles = current_organization.roles.order(:name)

      if @user.save
        assign_roles
        flash[:notice] = "User created successfully."
        redirect_to admin_user_path(@user)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @roles = current_organization.roles.order(:name)
    end

    def update
      @roles = current_organization.roles.order(:name)

      if @user.update(user_params.except(:password, :password_confirmation).merge(password_params))
        assign_roles
        flash[:notice] = "User updated successfully."
        redirect_to admin_user_path(@user)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def activate
      @user.update!(active: true)
      flash[:notice] = "User activated successfully."
      redirect_to admin_users_path
    end

    def deactivate
      if @user == current_user
        flash[:alert] = "You cannot deactivate yourself."
      else
        @user.update!(active: false)
        flash[:notice] = "User deactivated successfully."
      end
      redirect_to admin_users_path
    end

    private

    def set_user
      @user = current_organization.users.find(params[:id])
    end

    def user_params
      params.require(:user).permit(
        :first_name, :last_name, :email,
        :password, :password_confirmation
      )
    end

    def password_params
      if params[:user][:password].present?
        { password: params[:user][:password], password_confirmation: params[:user][:password_confirmation] }
      else
        {}
      end
    end

    def assign_roles
      return unless params[:user][:role_ids]

      role_ids = params[:user][:role_ids].reject(&:blank?).map(&:to_i)
      current_role_ids = @user.role_ids

      # Remove roles not in the new list
      (current_role_ids - role_ids).each do |role_id|
        @user.user_roles.find_by(role_id: role_id)&.destroy
      end

      # Add new roles
      (role_ids - current_role_ids).each do |role_id|
        role = current_organization.roles.find_by(id: role_id)
        @user.roles << role if role && !@user.roles.include?(role)
      end
    end

    def current_organization
      current_user.organization
    end
  end
end
