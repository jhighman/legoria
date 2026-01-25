# frozen_string_literal: true

class InterviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_interview, only: [:show, :edit, :update, :destroy, :confirm, :cancel, :complete, :mark_no_show]
  before_action :set_application, only: [:new, :create]

  def index
    authorize Interview
    @interviews = policy_scope(Interview)
                    .includes(:application, :job, :interview_participants, application: :candidate)
                    .order(scheduled_at: :asc)

    # Filter by status
    @interviews = @interviews.where(status: params[:status]) if params[:status].present?

    # Filter by type
    @interviews = @interviews.where(interview_type: params[:type]) if params[:type].present?

    # Filter for specific user (my interviews)
    if params[:mine] == "true"
      @interviews = @interviews.for_user(current_user.id)
    end

    # Filter by date range
    case params[:range]
    when "today"
      @interviews = @interviews.today
    when "week"
      @interviews = @interviews.this_week
    when "upcoming"
      @interviews = @interviews.upcoming
    when "past"
      @interviews = @interviews.past
    end

    respond_to do |format|
      format.html
      format.json { render json: @interviews }
    end
  end

  def show
    authorize @interview
  end

  def new
    @interview = @application.interviews.build
    authorize @interview
  end

  def create
    authorize Interview

    result = ScheduleInterviewService.call(
      application: @application,
      interview_type: interview_params[:interview_type],
      scheduled_at: parse_scheduled_at,
      scheduled_by: current_user,
      title: interview_params[:title],
      duration_minutes: interview_params[:duration_minutes],
      timezone: interview_params[:timezone],
      location: interview_params[:location],
      video_meeting_url: interview_params[:video_meeting_url],
      instructions: interview_params[:instructions],
      participants: build_participants
    )

    if result.success?
      @interview = result.value!
      respond_to do |format|
        format.html { redirect_to @interview, notice: "Interview scheduled successfully." }
        format.turbo_stream { redirect_to @interview, notice: "Interview scheduled successfully." }
        format.json { render json: @interview, status: :created }
      end
    else
      @interview = @application.interviews.build(interview_params)
      flash.now[:alert] = Array(result.failure).join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @interview
  end

  def update
    authorize @interview

    if params[:reschedule] && params[:interview][:scheduled_at].present?
      # Use reschedule service for time changes
      result = RescheduleInterviewService.call(
        interview: @interview,
        scheduled_at: parse_scheduled_at,
        rescheduled_by: current_user,
        duration_minutes: interview_params[:duration_minutes],
        location: interview_params[:location],
        video_meeting_url: interview_params[:video_meeting_url],
        reason: params[:reschedule_reason]
      )

      if result.success?
        redirect_to @interview, notice: "Interview rescheduled successfully."
      else
        flash.now[:alert] = Array(result.failure).join(", ")
        render :edit, status: :unprocessable_entity
      end
    else
      # Regular update for non-time changes
      if @interview.update(interview_params.except(:scheduled_at))
        redirect_to @interview, notice: "Interview updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    authorize @interview
    @interview.discard

    redirect_to interviews_path, notice: "Interview archived successfully."
  end

  # Custom actions for state transitions
  def confirm
    authorize @interview, :update?

    if @interview.confirm
      redirect_to @interview, notice: "Interview confirmed."
    else
      redirect_to @interview, alert: "Unable to confirm interview."
    end
  end

  def cancel
    authorize @interview, :cancel?

    result = CancelInterviewService.call(
      interview: @interview,
      cancelled_by: current_user,
      reason: params[:reason]
    )

    if result.success?
      redirect_to @interview, notice: "Interview cancelled."
    else
      redirect_to @interview, alert: Array(result.failure).join(", ")
    end
  end

  def complete
    authorize @interview, :update?

    if @interview.complete
      redirect_to @interview, notice: "Interview marked as completed."
    else
      redirect_to @interview, alert: "Unable to complete interview."
    end
  end

  def mark_no_show
    authorize @interview, :update?

    if @interview.mark_no_show
      redirect_to @interview, notice: "Interview marked as no-show."
    else
      redirect_to @interview, alert: "Unable to mark interview as no-show."
    end
  end

  private

  def set_interview
    @interview = Interview.find(params[:id])
  end

  def set_application
    @application = Application.find(params[:application_id])
  end

  def interview_params
    params.require(:interview).permit(
      :interview_type, :title, :scheduled_at, :scheduled_date, :scheduled_time,
      :duration_minutes, :timezone, :location, :video_meeting_url, :instructions,
      participant_ids: [], participant_roles: []
    )
  end

  def parse_scheduled_at
    if interview_params[:scheduled_at].present?
      Time.zone.parse(interview_params[:scheduled_at])
    elsif interview_params[:scheduled_date].present? && interview_params[:scheduled_time].present?
      Time.zone.parse("#{interview_params[:scheduled_date]} #{interview_params[:scheduled_time]}")
    end
  end

  def build_participants
    return [] unless params[:interview][:participant_ids].present?

    params[:interview][:participant_ids].reject(&:blank?).map.with_index do |user_id, index|
      role = params[:interview][:participant_roles]&.[](index) || "interviewer"
      { user: User.find(user_id), role: role }
    end
  end
end
