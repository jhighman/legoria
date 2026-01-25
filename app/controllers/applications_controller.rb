# frozen_string_literal: true

class ApplicationsController < ApplicationController
  before_action :set_job, only: [:new, :create]
  before_action :set_application, except: [:index, :new, :create]

  def index
    @applications = policy_scope(Application).kept

    # Apply filters
    @applications = @applications.by_status(params[:status]) if params[:status].present?
    @applications = @applications.by_job(params[:job_id]) if params[:job_id].present?
    @applications = @applications.by_source(params[:source]) if params[:source].present?
    @applications = @applications.starred if params[:starred] == "true"

    # Sorting
    @applications = case params[:sort]
                    when "oldest" then @applications.order(applied_at: :asc)
                    when "rating" then @applications.order(rating: :desc, applied_at: :desc)
                    when "activity" then @applications.order(last_activity_at: :desc)
                    else @applications.order(applied_at: :desc)
                    end

    @applications = @applications.includes(:candidate, :job, :current_stage)

    # Pagination
    @page = (params[:page] || 1).to_i
    @per_page = 25
    @total_count = @applications.count
    @applications = @applications.offset((@page - 1) * @per_page).limit(@per_page)
  end

  def show
    authorize @application
    @transitions = @application.stage_transitions.chronological.includes(:from_stage, :to_stage, :moved_by)
  end

  def new
    @candidate = params[:candidate_id] ? Candidate.find(params[:candidate_id]) : Candidate.new
    @application = @job.applications.build(candidate: @candidate)
    authorize @application
  end

  def create
    @application = @job.applications.build(application_params)
    authorize @application

    # Handle new candidate creation if needed
    if params[:create_candidate] == "1"
      @application.candidate = build_candidate_from_params
    end

    if @application.save
      # Create initial stage transition
      create_initial_transition

      redirect_to job_application_path(@job, @application), notice: "Application created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @application

    if @application.update(application_params)
      redirect_to @application, notice: "Application updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  # Stage movement
  def move_stage
    authorize @application, :move_stage?

    to_stage = Stage.find(params[:stage_id])
    result = MoveStageService.call(
      application: @application,
      to_stage: to_stage,
      moved_by: current_user,
      notes: params[:notes]
    )

    if result.success?
      respond_to do |format|
        format.html { redirect_to @application, notice: "Candidate moved to #{to_stage.name}." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @application, alert: error_message(result.failure) }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: error_message(result.failure) }) }
      end
    end
  end

  # Rejection
  def reject
    authorize @application, :reject?

    reason = RejectionReason.find(params[:rejection_reason_id])
    result = RejectApplicationService.call(
      application: @application,
      rejection_reason: reason,
      rejected_by: current_user,
      notes: params[:notes]
    )

    if result.success?
      respond_to do |format|
        format.html { redirect_to @application, notice: "Candidate rejected." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @application, alert: error_message(result.failure) }
        format.turbo_stream
      end
    end
  end

  # Withdrawal
  def withdraw
    authorize @application, :withdraw?

    if @application.can_withdraw?
      @application.withdraw!
      redirect_to @application, notice: "Application withdrawn."
    else
      redirect_to @application, alert: "Cannot withdraw this application."
    end
  end

  # Star/Unstar
  def star
    authorize @application, :star?
    @application.star!

    respond_to do |format|
      format.html { redirect_to @application, notice: "Application starred." }
      format.turbo_stream
    end
  end

  def unstar
    authorize @application, :unstar?
    @application.unstar!

    respond_to do |format|
      format.html { redirect_to @application, notice: "Star removed." }
      format.turbo_stream
    end
  end

  # Rating
  def rate
    authorize @application, :rate?

    rating = params[:rating].to_i
    if Application::RATING_RANGE.include?(rating)
      @application.rate!(rating)
      respond_to do |format|
        format.html { redirect_to @application, notice: "Rating saved." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @application, alert: "Invalid rating." }
        format.turbo_stream
      end
    end
  end

  private

  def set_job
    @job = Job.find(params[:job_id])
  end

  def set_application
    @application = if params[:job_id]
                     Job.find(params[:job_id]).applications.find(params[:id])
                   else
                     Application.find(params[:id])
                   end
  end

  def application_params
    params.require(:application).permit(
      :candidate_id, :source_type, :source_detail
    )
  end

  def build_candidate_from_params
    Candidate.new(
      organization: current_organization,
      first_name: params.dig(:candidate, :first_name),
      last_name: params.dig(:candidate, :last_name),
      email: params.dig(:candidate, :email),
      phone: params.dig(:candidate, :phone),
      location: params.dig(:candidate, :location)
    )
  end

  def create_initial_transition
    first_stage = @job.job_stages.order(:position).first&.stage
    return unless first_stage

    StageTransition.create!(
      application: @application,
      from_stage: nil,
      to_stage: first_stage,
      moved_by: current_user,
      notes: "Application submitted"
    )

    @application.update!(current_stage: first_stage)
  end

  def error_message(failure)
    case failure
    when Symbol then failure.to_s.humanize
    when Array then failure.join(", ")
    else failure.to_s
    end
  end
end
