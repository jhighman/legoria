# frozen_string_literal: true

module CandidatePortal
  class BaseController < ApplicationController
    skip_before_action :authenticate_user!
    before_action :authenticate_candidate!
    layout "candidate_portal"

    private

    def authenticate_candidate!
      unless current_candidate_account
        redirect_to new_candidate_account_session_path, alert: "Please sign in to access your candidate portal."
      end
    end

    def current_candidate_account
      @current_candidate_account ||= warden.authenticate(scope: :candidate_account)
    end

    def current_candidate
      @current_candidate ||= current_candidate_account&.candidate
    end

    helper_method :current_candidate_account, :current_candidate
  end
end
