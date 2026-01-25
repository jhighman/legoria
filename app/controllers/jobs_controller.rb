# frozen_string_literal: true

class JobsController < ApplicationController
  before_action :set_job, only: [:show, :edit, :update, :destroy,
                                  :submit_for_approval, :approve, :reject,
                                  :put_on_hold, :close, :reopen, :duplicate]

  def index
    @jobs = policy_scope(Job)
    @jobs = @jobs.by_status(params[:status]) if params[:status].present?
    @jobs = @jobs.by_department(params[:department_id]) if params[:department_id].present?
    @jobs = @jobs.order(created_at: :desc)
  end

  def pending_approval
    @jobs = policy_scope(Job).by_status(:pending_approval)
    @jobs = @jobs.by_hiring_manager(current_user.id) if current_user.hiring_manager? && !current_user.admin?
    @jobs = @jobs.order(created_at: :asc)
    render :index
  end

  def show
    authorize @job
  end

  def new
    @job = Job.new
    @job.recruiter = current_user if current_user.recruiter?

    # If creating from template
    if params[:template_id].present?
      template = JobTemplate.find(params[:template_id])
      @job = template.build_job(recruiter: current_user)
    end

    authorize @job
  end

  def create
    @job = Job.new(job_params)
    @job.recruiter ||= current_user if current_user.recruiter?
    authorize @job

    if @job.save
      redirect_to @job, notice: "Job was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @job
  end

  def update
    authorize @job

    if @job.update(job_params)
      redirect_to @job, notice: "Job was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @job
    @job.discard!
    redirect_to jobs_url, notice: "Job was successfully archived."
  end

  # Workflow actions
  def submit_for_approval
    authorize @job, :submit_for_approval?

    if @job.can_submit_for_approval?
      @job.submit_for_approval!
      create_approval_request
      redirect_to @job, notice: "Job submitted for approval."
    else
      redirect_to @job, alert: "Cannot submit this job for approval."
    end
  end

  def approve
    authorize @job, :approve?

    approval = @job.job_approvals.pending.find_by(approver: current_user)
    if approval&.approve!(notes: params[:notes])
      redirect_to @job, notice: "Job approved and now open for applications."
    else
      redirect_to @job, alert: "Cannot approve this job."
    end
  end

  def reject
    authorize @job, :reject?

    approval = @job.job_approvals.pending.find_by(approver: current_user)
    if approval&.reject!(notes: params[:notes])
      redirect_to @job, notice: "Job rejected and returned to draft."
    else
      redirect_to @job, alert: "Cannot reject this job."
    end
  end

  def put_on_hold
    authorize @job, :put_on_hold?

    if @job.can_put_on_hold?
      @job.put_on_hold!
      redirect_to @job, notice: "Job put on hold."
    else
      redirect_to @job, alert: "Cannot put this job on hold."
    end
  end

  def close
    authorize @job, :close?

    if @job.can_close?
      @job.close_reason = params[:close_reason]
      @job.close!
      redirect_to @job, notice: "Job closed."
    else
      redirect_to @job, alert: "Cannot close this job."
    end
  end

  def reopen
    authorize @job, :reopen?

    if @job.can_reopen?
      @job.reopen!
      redirect_to @job, notice: "Job reopened."
    else
      redirect_to @job, alert: "Cannot reopen this job."
    end
  end

  def duplicate
    authorize @job, :duplicate?

    new_job = @job.duplicate
    new_job.title = "Copy of #{@job.title}"

    if new_job.save
      redirect_to edit_job_path(new_job), notice: "Job duplicated. Please review and save."
    else
      redirect_to @job, alert: "Failed to duplicate job."
    end
  end

  private

  def set_job
    @job = Job.find(params[:id])
  end

  def job_params
    params.require(:job).permit(
      :title, :description, :requirements, :internal_notes,
      :department_id, :hiring_manager_id,
      :location, :location_type, :employment_type,
      :salary_min, :salary_max, :salary_currency, :salary_visible,
      :headcount
    )
  end

  def create_approval_request
    return unless @job.hiring_manager.present?

    @job.job_approvals.create!(
      approver: @job.hiring_manager,
      status: :pending,
      sequence: 0
    )
  end
end
