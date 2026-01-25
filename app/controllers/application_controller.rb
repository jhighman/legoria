# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Set Current context for multi-tenancy
  before_action :set_current_context

  # Require authentication for all actions by default
  before_action :authenticate_user!

  # Handle Pundit authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_current_context
    return unless user_signed_in?

    Current.user = current_user
    Current.organization = current_user.organization
    Current.request_id = request.request_id
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end

  # Helper to get current organization
  def current_organization
    Current.organization
  end
  helper_method :current_organization
end
