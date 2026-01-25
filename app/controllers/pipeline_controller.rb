# frozen_string_literal: true

class PipelineController < ApplicationController
  before_action :set_job
  before_action :set_application, only: [:move_stage, :reject, :star, :unstar, :rate]

  def show
    authorize @job, :show?
    @stages = @job.stages.ordered
    @applications = @job.applications.includes(:candidate, :current_stage)
                        .kept
                        .order(applied_at: :desc)

    # Apply filters
    @applications = apply_filters(@applications)

    # Group by stage for Kanban view
    @applications_by_stage = @applications.group_by(&:current_stage_id)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def list
    authorize @job, :show?
    @applications = @job.applications.includes(:candidate, :current_stage)
                        .kept
                        .order(applied_at: :desc)

    @applications = apply_filters(@applications)
  end

  def move_stage
    authorize @application, :update?

    @from_stage = @application.current_stage
    @to_stage = @job.stages.find(params[:stage_id])

    result = MoveStageService.call(
      application: @application,
      to_stage: @to_stage,
      moved_by: current_user,
      notes: params[:notes]
    )

    respond_to do |format|
      if result.success?
        @transition = result.value!
        format.turbo_stream
        format.html { redirect_to job_pipeline_path(@job), notice: "Candidate moved to #{@to_stage.name}." }
      else
        error_message = format_error(result.failure)
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: error_message }) }
        format.html { redirect_to job_pipeline_path(@job), alert: error_message }
      end
    end
  end

  def reject
    authorize @application, :reject?

    @rejection_reason = RejectionReason.find_by(id: params[:rejection_reason_id])

    result = RejectApplicationService.call(
      application: @application,
      rejection_reason: @rejection_reason,
      notes: params[:notes],
      rejected_by: current_user
    )

    respond_to do |format|
      if result.success?
        format.turbo_stream
        format.html { redirect_to job_pipeline_path(@job), notice: "Candidate rejected." }
      else
        error_message = format_error(result.failure)
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: error_message }) }
        format.html { redirect_to job_pipeline_path(@job), alert: error_message }
      end
    end
  end

  def star
    authorize @application, :update?
    @application.star!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to job_pipeline_path(@job) }
    end
  end

  def unstar
    authorize @application, :update?
    @application.unstar!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to job_pipeline_path(@job) }
    end
  end

  def rate
    authorize @application, :update?
    rating_value = params[:rating].to_i
    rating_value = nil if rating_value.zero?
    @application.update!(rating: rating_value)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to job_pipeline_path(@job) }
    end
  end

  private

  def set_job
    @job = Job.find(params[:job_id])
  end

  def set_application
    @application = @job.applications.find(params[:id])
  end

  def apply_filters(applications)
    applications = applications.by_source(params[:source]) if params[:source].present?
    applications = applications.starred if params[:starred] == "true"
    applications = applications.where(rating: params[:rating]) if params[:rating].present?

    if params[:applied_after].present?
      applications = applications.where("applied_at >= ?", Date.parse(params[:applied_after]))
    end

    if params[:applied_before].present?
      applications = applications.where("applied_at <= ?", Date.parse(params[:applied_before]))
    end

    applications
  end

  def format_error(failure)
    case failure
    when Symbol
      failure.to_s.humanize
    when Array
      failure.join(", ")
    else
      failure.to_s
    end
  end
end
