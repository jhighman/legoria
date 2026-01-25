# frozen_string_literal: true

# Public career site controller - no authentication required
# Organization is resolved from subdomain/custom domain
class CareerSiteController < ApplicationController
  include SubdomainOrganization

  skip_before_action :authenticate_user!
  layout "career_site"

  before_action :set_job, only: [:show]

  rescue_from ActiveRecord::RecordNotFound, with: :job_not_found

  def index
    @jobs = Job.unscoped
               .kept
               .where(organization_id: @organization.id, status: "open")
               .includes(:department)
               .order(created_at: :desc)

    # Apply filters
    @jobs = @jobs.where(department_id: params[:department]) if params[:department].present?
    @jobs = @jobs.where(location_type: params[:location_type]) if params[:location_type].present?
    @jobs = @jobs.where(employment_type: params[:employment_type]) if params[:employment_type].present?

    # Search by title
    if params[:q].present?
      @jobs = @jobs.where("title LIKE ?", "%#{params[:q]}%")
    end

    # Get filter options
    @departments = Department.unscoped.where(organization_id: @organization.id).order(:name)
    @location_types = LookupService.all_values("location_type", organization: @organization)
    @employment_types = LookupService.all_values("employment_type", organization: @organization)
  end

  def show
    @stages = @job.stages.ordered
  end

  private

  def set_job
    @job = Job.unscoped
              .kept
              .where(organization_id: @organization.id, status: "open")
              .find(params[:id])
  end

  def job_not_found
    render file: Rails.root.join("public", "404.html"), status: :not_found, layout: false
  end
end
