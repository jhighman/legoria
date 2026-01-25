# frozen_string_literal: true

class CandidatesController < ApplicationController
  before_action :set_candidate, only: [:show, :edit, :update, :destroy, :merge, :add_note, :upload_resume]

  def index
    @candidates = policy_scope(Candidate).kept.unmerged

    # Apply search
    @candidates = @candidates.search(params[:q]) if params[:q].present?

    # Apply filters
    @candidates = apply_filters(@candidates)

    # Sorting
    @candidates = apply_sorting(@candidates)

    # Pagination (using simple offset/limit for now)
    @page = (params[:page] || 1).to_i
    @per_page = 25
    @total_count = @candidates.count
    @candidates = @candidates.offset((@page - 1) * @per_page).limit(@per_page)

    # Include associations for display
    @candidates = @candidates.includes(:applications, applications: [:job, :current_stage])
  end

  def show
    authorize @candidate
    @applications = @candidate.applications.includes(:job, :current_stage).recent
    @resumes = @candidate.resumes.primary_first
    @notes = @candidate.candidate_notes.visible_to(current_user).pinned_first
    @timeline = build_timeline
  end

  def new
    @candidate = Candidate.new
    authorize @candidate
  end

  def create
    @candidate = Candidate.new(candidate_params)
    authorize @candidate

    if @candidate.save
      redirect_to @candidate, notice: "Candidate was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @candidate
  end

  def update
    authorize @candidate

    if @candidate.update(candidate_params)
      redirect_to @candidate, notice: "Candidate was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @candidate
    @candidate.discard!
    redirect_to candidates_url, notice: "Candidate was successfully archived."
  end

  # Additional actions
  def merge
    authorize @candidate, :merge?
    target = Candidate.find(params[:target_id])

    if @candidate.merge_into!(target)
      redirect_to target, notice: "Candidates merged successfully."
    else
      redirect_to @candidate, alert: "Failed to merge candidates."
    end
  end

  def add_note
    authorize @candidate, :add_note?

    @note = @candidate.candidate_notes.build(note_params)
    @note.user = current_user

    if @note.save
      respond_to do |format|
        format.html { redirect_to @candidate, notice: "Note added." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @candidate, alert: "Failed to add note." }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("note_form", partial: "candidates/note_form", locals: { candidate: @candidate, note: @note }) }
      end
    end
  end

  def upload_resume
    authorize @candidate, :upload_resume?

    @resume = @candidate.resumes.build(resume_params)

    if @resume.save
      respond_to do |format|
        format.html { redirect_to @candidate, notice: "Resume uploaded." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @candidate, alert: "Failed to upload resume." }
        format.turbo_stream
      end
    end
  end

  private

  def set_candidate
    @candidate = Candidate.find(params[:id])
  end

  def candidate_params
    params.require(:candidate).permit(
      :first_name, :last_name, :email, :phone, :ssn,
      :location, :linkedin_url, :portfolio_url, :summary
    )
  end

  def note_params
    params.require(:candidate_note).permit(:content, :visibility)
  end

  def resume_params
    params.require(:resume).permit(:file, :primary).tap do |p|
      if p[:file].present?
        p[:filename] = p[:file].original_filename
        p[:content_type] = p[:file].content_type
        p[:file_size] = p[:file].size
        p[:storage_key] = SecureRandom.uuid
      end
    end
  end

  def apply_filters(scope)
    # Filter by source type
    if params[:source].present?
      scope = scope.joins(:candidate_sources)
                   .where(candidate_sources: { source_type: params[:source] })
    end

    # Filter by has applications
    if params[:has_applications] == "true"
      scope = scope.with_applications
    elsif params[:has_applications] == "false"
      scope = scope.without_applications
    end

    # Filter by date range
    if params[:created_after].present?
      scope = scope.where("candidates.created_at >= ?", Date.parse(params[:created_after]))
    end

    if params[:created_before].present?
      scope = scope.where("candidates.created_at <= ?", Date.parse(params[:created_before]))
    end

    scope
  end

  def apply_sorting(scope)
    case params[:sort]
    when "name_asc"
      scope.order(last_name: :asc, first_name: :asc)
    when "name_desc"
      scope.order(last_name: :desc, first_name: :desc)
    when "oldest"
      scope.order(created_at: :asc)
    else
      scope.order(created_at: :desc)
    end
  end

  def build_timeline
    timeline_items = []

    # Add applications
    @candidate.applications.includes(:job, :current_stage).each do |app|
      timeline_items << {
        type: "application",
        date: app.applied_at,
        title: "Applied to #{app.job.title}",
        description: "Status: #{app.status_label}",
        icon: "briefcase",
        record: app
      }
    end

    # Add stage transitions
    StageTransition.joins(:application)
                   .where(applications: { candidate_id: @candidate.id })
                   .includes(:from_stage, :to_stage, :moved_by)
                   .each do |transition|
      timeline_items << {
        type: "transition",
        date: transition.created_at,
        title: transition.description,
        description: transition.notes,
        icon: "arrow-right",
        record: transition
      }
    end

    # Add notes (visible to current user)
    @candidate.candidate_notes.visible_to(current_user).each do |note|
      timeline_items << {
        type: "note",
        date: note.created_at,
        title: "Note by #{note.author_name}",
        description: note.excerpt,
        icon: "message-square",
        record: note
      }
    end

    # Sort by date descending
    timeline_items.sort_by { |item| -item[:date].to_i }
  end
end
