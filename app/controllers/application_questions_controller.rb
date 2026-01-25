# frozen_string_literal: true

class ApplicationQuestionsController < ApplicationController
  before_action :set_job
  before_action :set_question, only: [:edit, :update, :destroy, :move_up, :move_down, :toggle_active]

  def index
    authorize ApplicationQuestion
    @questions = @job.application_questions.ordered
  end

  def new
    @question = @job.application_questions.build
    authorize @question
  end

  def edit
    authorize @question
  end

  def create
    @question = @job.application_questions.build(question_params)
    authorize @question

    if @question.save
      redirect_to job_application_questions_path(@job), notice: "Question was created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @question

    if @question.update(question_params)
      redirect_to job_application_questions_path(@job), notice: "Question was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @question
    @question.destroy
    redirect_to job_application_questions_path(@job), notice: "Question was deleted."
  end

  def move_up
    authorize @question, :update?
    @question.move_up!
    redirect_to job_application_questions_path(@job)
  end

  def move_down
    authorize @question, :update?
    @question.move_down!
    redirect_to job_application_questions_path(@job)
  end

  def toggle_active
    authorize @question, :update?

    if @question.active?
      @question.deactivate!
      redirect_to job_application_questions_path(@job), notice: "Question was deactivated."
    else
      @question.activate!
      redirect_to job_application_questions_path(@job), notice: "Question was activated."
    end
  end

  private

  def set_job
    @job = Job.find(params[:job_id])
  end

  def set_question
    @question = @job.application_questions.find(params[:id])
  end

  def question_params
    params.require(:application_question).permit(
      :question,
      :description,
      :question_type,
      :required,
      :min_length,
      :max_length,
      :min_value,
      :max_value,
      :position,
      :placeholder,
      :help_text,
      :active,
      options: []
    )
  end
end
