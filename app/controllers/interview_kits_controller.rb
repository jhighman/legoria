# frozen_string_literal: true

class InterviewKitsController < ApplicationController
  before_action :set_interview_kit, only: [:show, :edit, :update, :destroy, :duplicate, :activate, :deactivate, :set_default]

  def index
    @interview_kits = policy_scope(InterviewKit)
                       .includes(:job, :stage)
                       .then { |q| params[:type].present? ? q.by_type(params[:type]) : q }
                       .then { |q| params[:job_id].present? ? q.for_job(params[:job_id]) : q }
                       .then { |q| params[:search].present? ? q.search(params[:search]) : q }
                       .then { |q| params[:active] == "false" ? q.inactive : q.active }
                       .order(updated_at: :desc)
                       .page(params[:page])
  end

  def show
    authorize @interview_kit
    @questions = @interview_kit.interview_kit_questions.includes(:question_bank).ordered
  end

  def new
    @interview_kit = InterviewKit.new
    authorize @interview_kit
    load_form_data
  end

  def edit
    authorize @interview_kit
    load_form_data
  end

  def create
    @interview_kit = InterviewKit.new(interview_kit_params)
    authorize @interview_kit

    if @interview_kit.save
      redirect_to interview_kit_path(@interview_kit), notice: "Interview kit was created successfully."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @interview_kit

    if @interview_kit.update(interview_kit_params)
      redirect_to interview_kit_path(@interview_kit), notice: "Interview kit was updated successfully."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @interview_kit

    @interview_kit.deactivate!
    redirect_to interview_kits_path, notice: "Interview kit was archived."
  end

  def duplicate
    authorize @interview_kit, :create?

    new_kit = @interview_kit.duplicate
    redirect_to edit_interview_kit_path(new_kit), notice: "Interview kit was duplicated. You can now edit the copy."
  end

  def activate
    authorize @interview_kit, :update?

    @interview_kit.activate!
    redirect_to interview_kits_path, notice: "Interview kit was activated."
  end

  def deactivate
    authorize @interview_kit, :update?

    @interview_kit.deactivate!
    redirect_to interview_kits_path, notice: "Interview kit was deactivated."
  end

  def set_default
    authorize @interview_kit, :update?

    @interview_kit.set_as_default!
    redirect_to interview_kits_path, notice: "Interview kit was set as default."
  end

  private

  def set_interview_kit
    @interview_kit = InterviewKit.find(params[:id])
  end

  def load_form_data
    @jobs = Job.kept.active.order(:title)
    @stages = Stage.order(:position)
    @question_banks = QuestionBank.active.order(:question)
  end

  def interview_kit_params
    params.require(:interview_kit).permit(
      :name,
      :description,
      :interview_type,
      :job_id,
      :stage_id,
      :introduction_notes,
      :closing_notes,
      :active,
      :is_default,
      interview_kit_questions_attributes: [
        :id,
        :question_bank_id,
        :question,
        :guidance,
        :position,
        :time_allocation,
        :_destroy
      ]
    )
  end
end
