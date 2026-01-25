# frozen_string_literal: true

module Admin
  class AuditLogsController < BaseController
    def index
      @audit_logs = AuditLog.where(organization_id: current_organization.id)
                            .includes(:user)
                            .recent

      # Apply filters
      @audit_logs = apply_filters(@audit_logs)

      # Pagination
      @page = (params[:page] || 1).to_i
      @per_page = 50
      @total_count = @audit_logs.count
      @audit_logs = @audit_logs.offset((@page - 1) * @per_page).limit(@per_page)

      # Get filter options
      @action_options = AuditLog.where(organization_id: current_organization.id)
                                .distinct.pluck(:action).sort
      @user_options = User.where(organization_id: current_organization.id)
                          .active.order(:first_name, :last_name)
      @auditable_types = AuditLog.where(organization_id: current_organization.id)
                                 .distinct.pluck(:auditable_type).sort
    end

    def show
      @audit_log = AuditLog.find(params[:id])

      # Ensure it belongs to current organization
      unless @audit_log.organization_id == current_organization.id
        redirect_to admin_audit_logs_path, alert: "Audit log not found."
      end
    end

    private

    def apply_filters(logs)
      logs = logs.by_action(params[:action_filter]) if params[:action_filter].present?
      logs = logs.by_user(params[:user_id]) if params[:user_id].present?
      logs = logs.by_auditable_type(params[:auditable_type]) if params[:auditable_type].present?

      if params[:start_date].present? || params[:end_date].present?
        logs = logs.by_date_range(
          params[:start_date].presence&.to_date,
          params[:end_date].presence&.to_date
        )
      end

      if params[:search].present?
        search_term = "%#{params[:search]}%"
        logs = logs.where(
          "action LIKE ? OR request_id LIKE ?",
          search_term, search_term
        )
      end

      logs
    end
  end
end
