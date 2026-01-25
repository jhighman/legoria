# frozen_string_literal: true

# Public controller for job applications - no authentication required
# Organization is resolved from subdomain/custom domain
class PublicApplicationsController < ApplicationController
  include SubdomainOrganization

  skip_before_action :authenticate_user!
  layout "career_site"

  before_action :set_job, only: [:new, :create]

  def new
    @candidate = Candidate.new
    @application = Application.new
  end

  def create
    ActiveRecord::Base.transaction do
      # Create or find existing candidate
      @candidate = find_or_create_candidate

      if @candidate.errors.any?
        render :new, status: :unprocessable_entity
        return
      end

      # Create application
      @application = build_application

      if @application.save
        # Send confirmation email
        JobApplicationMailer.application_received(@application).deliver_later

        redirect_to application_status_check_path(@application.tracking_token),
                    notice: "Your application has been submitted successfully!"
      else
        render :new, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    @candidate ||= Candidate.new(candidate_params)
    @application ||= Application.new
    flash.now[:alert] = "There was an error submitting your application. Please try again."
    render :new, status: :unprocessable_entity
  end

  def status_lookup
    # Form to enter tracking token or email
  end

  def status
    @application = Application.unscoped
                              .includes(:job, :candidate, :current_stage, stage_transitions: [:from_stage, :to_stage])
                              .find_by(tracking_token: params[:token])

    if @application.nil?
      redirect_to application_status_path, alert: "Application not found. Please check your tracking code."
    end
  end

  private

  def set_job
    @job = Job.unscoped
              .kept
              .where(organization_id: @organization.id, status: "open")
              .find(params[:id])
  end

  def candidate_params
    params.require(:candidate).permit(
      :first_name, :last_name, :email, :phone,
      :linkedin_url, :portfolio_url, :current_company,
      :current_title, :cover_letter
    )
  end

  def application_params
    params.permit(:source_type, :source_detail, :referral_code)
  end

  def find_or_create_candidate
    # Check if candidate already exists by email
    existing = Candidate.unscoped.find_by(
      organization_id: @organization.id,
      email: candidate_params[:email]&.downcase&.strip
    )

    if existing
      # Update with new information if provided
      existing.update(candidate_params.compact_blank)
      existing
    else
      # Create new candidate
      candidate = Candidate.new(candidate_params)
      candidate.organization_id = @organization.id
      candidate.source = determine_source
      candidate.save!
      candidate
    end
  end

  def build_application
    # Get the first stage for the job
    first_stage = @job.stages.ordered.first

    application = Application.new(
      organization_id: @organization.id,
      job: @job,
      candidate: @candidate,
      current_stage: first_stage,
      source_type: application_params[:source_type].presence || "career_site",
      source_detail: application_params[:source_detail].presence || application_params[:referral_code],
      applied_at: Time.current
    )

    # Generate tracking token
    application.tracking_token = generate_tracking_token

    # Handle resume upload
    if params[:resume].present?
      attach_resume(application)
    end

    application
  end

  def generate_tracking_token
    loop do
      token = SecureRandom.urlsafe_base64(16)
      break token unless Application.unscoped.exists?(tracking_token: token)
    end
  end

  def attach_resume(application)
    # Create resume record and attach file
    if @candidate.persisted? && params[:resume].present?
      resume = @candidate.resumes.build(
        primary: @candidate.resumes.empty?
      )
      resume.file.attach(params[:resume])
      resume.save
    end
  end

  def determine_source
    if application_params[:referral_code].present?
      "referral"
    else
      "career_site"
    end
  end
end
