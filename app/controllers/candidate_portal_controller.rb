# frozen_string_literal: true

class CandidatePortalController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :authenticate_candidate!
  layout "candidate_portal"

  def dashboard
    @applications = current_candidate.applications
                                      .includes(:job, :current_stage)
                                      .order(updated_at: :desc)
    @upcoming_interviews = Interview.joins(:application)
                                     .where(applications: { candidate_id: current_candidate.id })
                                     .upcoming
                                     .includes(:job)
                                     .limit(5)
  end

  def applications
    @applications = current_candidate.applications
                                      .includes(:job, :current_stage, :organization)
                                      .order(applied_at: :desc)
                                      .page(params[:page])
  end

  def application
    @application = current_candidate.applications
                                     .includes(:job, :current_stage, :stage_transitions, :interviews)
                                     .find(params[:id])
  end

  def documents
    @documents = current_candidate.candidate_documents
                                   .with_attached_file
                                   .order(created_at: :desc)
  end

  def upload_document
    @document = current_candidate.candidate_documents.build(document_params)

    if @document.save
      redirect_to candidate_portal_documents_path, notice: "Document uploaded successfully."
    else
      @documents = current_candidate.candidate_documents.order(created_at: :desc)
      render :documents, status: :unprocessable_entity
    end
  end

  def delete_document
    @document = current_candidate.candidate_documents.find(params[:id])
    @document.destroy
    redirect_to candidate_portal_documents_path, notice: "Document deleted."
  end

  def profile
    @candidate = current_candidate
    @account = current_candidate_account
  end

  def update_profile
    @candidate = current_candidate
    @account = current_candidate_account

    if @candidate.update(candidate_params) && @account.update(account_params)
      redirect_to candidate_portal_profile_path, notice: "Profile updated successfully."
    else
      render :profile, status: :unprocessable_entity
    end
  end

  def job_alerts
    @account = current_candidate_account
  end

  def update_job_alerts
    @account = current_candidate_account

    if @account.update(job_alert_params)
      redirect_to candidate_portal_job_alerts_path, notice: "Job alert preferences updated."
    else
      render :job_alerts, status: :unprocessable_entity
    end
  end

  private

  def authenticate_candidate!
    unless current_candidate_account
      redirect_to candidate_login_path, alert: "Please sign in to access your candidate portal."
    end
  end

  def current_candidate_account
    @current_candidate_account ||= warden.authenticate(scope: :candidate_account)
  end

  def current_candidate
    @current_candidate ||= current_candidate_account&.candidate
  end

  helper_method :current_candidate_account, :current_candidate

  def document_params
    params.require(:candidate_document).permit(:name, :document_type, :description, :file)
  end

  def candidate_params
    params.require(:candidate).permit(:first_name, :last_name, :phone, :location, :linkedin_url, :portfolio_url)
  end

  def account_params
    params.require(:candidate_account).permit(:email_notifications)
  end

  def job_alert_params
    params.require(:candidate_account).permit(:job_alerts, job_alert_criteria: {})
  end
end
