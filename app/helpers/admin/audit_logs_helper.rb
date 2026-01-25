# frozen_string_literal: true

module Admin
  module AuditLogsHelper
    def action_badge_class(action)
      category = action.split(".").first
      case category
      when "job"
        "bg-primary"
      when "application"
        "bg-info"
      when "candidate"
        "bg-success"
      when "user"
        "bg-warning text-dark"
      when "system"
        "bg-secondary"
      else
        "bg-light text-dark"
      end
    end

    def filter_params
      params.permit(:action_filter, :user_id, :auditable_type, :start_date, :end_date, :search).to_h
    end
  end
end
