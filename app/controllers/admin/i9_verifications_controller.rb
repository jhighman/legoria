# frozen_string_literal: true

module Admin
  class I9VerificationsController < BaseController
    skip_before_action :require_admin!
    before_action :require_hr!
    before_action :set_i9_verification, only: [:show, :edit, :update, :section2, :complete_section2, :section3, :complete_section3]

    def index
      @i9_verifications = policy_scope(I9Verification)
                          .includes(:candidate, :application, application: :job)
                          .order(created_at: :desc)

      apply_filters

      @i9_verifications = @i9_verifications.limit(100)
    end

    def pending
      @i9_verifications = policy_scope(I9Verification)
                          .where(status: %w[pending_section1 section1_complete pending_section2])
                          .includes(:candidate, :application, application: :job)
                          .order(:deadline_section2)
                          .limit(100)

      render :index
    end

    def overdue
      @i9_verifications = policy_scope(I9Verification)
                          .where("deadline_section2 < ?", Date.current)
                          .where.not(status: %w[verified failed expired])
                          .includes(:candidate, :application, application: :job)
                          .order(:deadline_section2)
                          .limit(100)

      render :index
    end

    def show
      authorize @i9_verification
      @documents = @i9_verification.i9_documents.includes(file_attachment: :blob)
      @work_authorization = @i9_verification.work_authorization
    end

    def new
      @i9_verification = I9Verification.new
      @applications = policy_scope(Application)
                      .where(status: %w[offered hired])
                      .where.not(id: I9Verification.select(:application_id))
                      .includes(:candidate, :job)
    end

    def create
      @application = policy_scope(Application).find(params[:i9_verification][:application_id])

      result = InitiateI9VerificationService.call(
        application: @application,
        expected_start_date: params[:i9_verification][:employee_start_date]
      )

      if result.success?
        redirect_to admin_i9_verification_path(result.value!), notice: "I-9 verification initiated successfully."
      else
        @applications = policy_scope(Application)
                        .where(status: %w[offered hired])
                        .includes(:candidate, :job)
        flash.now[:alert] = "Failed to initiate I-9: #{result.failure}"
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @i9_verification
    end

    def update
      authorize @i9_verification

      if @i9_verification.update(i9_verification_params)
        redirect_to admin_i9_verification_path(@i9_verification), notice: "I-9 verification updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def section2
      authorize @i9_verification

      unless @i9_verification.section1_complete? || @i9_verification.pending_section2?
        redirect_to admin_i9_verification_path(@i9_verification),
                    alert: "Section 2 cannot be completed until Section 1 is complete."
        return
      end

      @documents = @i9_verification.i9_documents
    end

    def complete_section2
      authorize @i9_verification

      result = CompleteI9Section2Service.call(
        i9_verification: @i9_verification,
        section2_params: section2_params,
        documents: parse_documents,
        completed_by: current_user,
        ip_address: request.remote_ip
      )

      if result.success?
        redirect_to admin_i9_verification_path(@i9_verification),
                    notice: "Section 2 completed successfully."
      else
        error_message = format_error(result.failure)
        flash.now[:alert] = error_message
        @documents = @i9_verification.i9_documents
        render :section2, status: :unprocessable_entity
      end
    end

    def section3
      authorize @i9_verification

      unless @i9_verification.verified?
        redirect_to admin_i9_verification_path(@i9_verification),
                    alert: "Section 3 can only be completed for verified I-9s."
        return
      end
    end

    def complete_section3
      authorize @i9_verification

      @i9_verification.assign_attributes(section3_params)
      @i9_verification.section3_completed_at = Time.current
      @i9_verification.section3_completed_by = current_user

      if @i9_verification.save
        # Update work authorization if expiration changed
        if section3_params[:new_expiration_date].present?
          @i9_verification.work_authorization&.update(
            valid_until: section3_params[:new_expiration_date],
            reverification_required: false
          )
        end

        redirect_to admin_i9_verification_path(@i9_verification),
                    notice: "Section 3 reverification completed."
      else
        render :section3, status: :unprocessable_entity
      end
    end

    private

    def require_hr!
      unless current_user&.admin? || current_user&.recruiter?
        flash[:alert] = "You must be HR or an administrator to access this area."
        redirect_to root_path
      end
    end

    def set_i9_verification
      @i9_verification = I9Verification.find(params[:id])
    end

    def apply_filters
      @i9_verifications = @i9_verifications.where(status: params[:status]) if params[:status].present?

      if params[:deadline].present?
        case params[:deadline]
        when "today"
          @i9_verifications = @i9_verifications.where(deadline_section2: Date.current)
        when "this_week"
          @i9_verifications = @i9_verifications.where(deadline_section2: Date.current..Date.current.end_of_week)
        when "overdue"
          @i9_verifications = @i9_verifications.where("deadline_section2 < ?", Date.current)
        end
      end

      if params[:search].present?
        @i9_verifications = @i9_verifications.joins(:candidate)
          .where("candidates.first_name LIKE :q OR candidates.last_name LIKE :q OR candidates.email LIKE :q",
                 q: "%#{params[:search]}%")
      end
    end

    def i9_verification_params
      params.require(:i9_verification).permit(
        :employee_start_date,
        :remote_verification,
        :authorized_representative_id,
        :late_completion_reason
      )
    end

    def section2_params
      params.require(:i9_verification).permit(
        :employer_title,
        :employer_organization_name,
        :employer_organization_address,
        :late_reason
      )
    end

    def section3_params
      params.require(:i9_verification).permit(
        :rehire_date,
        :new_document_title,
        :new_document_number,
        :new_expiration_date
      )
    end

    def parse_documents
      return [] unless params[:documents].present?

      params[:documents].map do |doc|
        {
          list_type: doc[:list_type],
          document_type: doc[:document_type],
          document_title: doc[:document_title],
          issuing_authority: doc[:issuing_authority],
          document_number: doc[:document_number],
          expiration_date: doc[:expiration_date],
          file: doc[:file]
        }
      end
    end

    def format_error(failure)
      case failure
      when Symbol
        I18n.t("i9.errors.#{failure}", default: failure.to_s.humanize)
      when Array
        failure.join(", ")
      else
        failure.to_s
      end
    end
  end
end
