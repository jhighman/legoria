# frozen_string_literal: true

module Admin
  class WorkAuthorizationsController < BaseController
    skip_before_action :require_admin!
    before_action :require_hr!
    before_action :set_work_authorization, only: [:show]

    def index
      @work_authorizations = policy_scope(WorkAuthorization)
                             .includes(:candidate, :i9_verification)
                             .order(valid_until: :asc)

      apply_filters

      @work_authorizations = @work_authorizations.limit(100)
    end

    def expiring
      @work_authorizations = policy_scope(WorkAuthorization)
                             .expiring_soon(90)
                             .includes(:candidate, :i9_verification)
                             .order(valid_until: :asc)
                             .limit(100)

      render :index
    end

    def show
      authorize @work_authorization
      @candidate = @work_authorization.candidate
      @i9_verification = @work_authorization.i9_verification
    end

    private

    def require_hr!
      unless current_user&.admin? || current_user&.recruiter?
        flash[:alert] = "You must be HR or an administrator to access this area."
        redirect_to root_path
      end
    end

    def set_work_authorization
      @work_authorization = WorkAuthorization.find(params[:id])
    end

    def apply_filters
      @work_authorizations = @work_authorizations.where(authorization_type: params[:type]) if params[:type].present?

      if params[:expiring].present?
        case params[:expiring]
        when "30"
          @work_authorizations = @work_authorizations.expiring_soon(30)
        when "60"
          @work_authorizations = @work_authorizations.expiring_soon(60)
        when "90"
          @work_authorizations = @work_authorizations.expiring_soon(90)
        end
      end

      if params[:indefinite].present?
        @work_authorizations = @work_authorizations.where(indefinite: params[:indefinite] == "true")
      end

      if params[:search].present?
        @work_authorizations = @work_authorizations.joins(:candidate)
          .where("candidates.first_name LIKE :q OR candidates.last_name LIKE :q OR candidates.email LIKE :q",
                 q: "%#{params[:search]}%")
      end
    end
  end
end
