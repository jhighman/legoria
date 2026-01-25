# frozen_string_literal: true

module CandidatePortal
  class I9VerificationsController < BaseController
    before_action :set_i9_verification

    def show
      if @i9_verification.pending_section1?
        redirect_to section1_candidate_portal_i9_verification_path(@i9_verification)
      end
    end

    def section1
      unless @i9_verification.pending_section1?
        redirect_to candidate_portal_i9_verification_path(@i9_verification),
                    notice: "Section 1 has already been completed."
        return
      end

      @application = @i9_verification.application
      @job = @application.job
    end

    def complete_section1
      result = CompleteI9Section1Service.call(
        i9_verification: @i9_verification,
        section1_params: section1_params,
        request_info: {
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        }
      )

      if result.success?
        redirect_to candidate_portal_i9_verification_path(@i9_verification),
                    notice: "Section 1 completed successfully. Your employer will complete Section 2."
      else
        flash.now[:alert] = result.failure[:error]
        @application = @i9_verification.application
        @job = @application.job
        render :section1, status: :unprocessable_entity
      end
    end

    private

    def set_i9_verification
      @i9_verification = current_candidate.i9_verifications.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to candidate_portal_dashboard_path, alert: "I-9 verification not found."
    end

    def section1_params
      params.require(:i9_verification).permit(
        :citizenship_status,
        :alien_number,
        :alien_expiration_date,
        :i94_number,
        :foreign_passport_number,
        :foreign_passport_country,
        :attestation_accepted
      )
    end
  end
end
