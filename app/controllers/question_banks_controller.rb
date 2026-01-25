# frozen_string_literal: true

class QuestionBanksController < ApplicationController
  before_action :set_question_bank, only: [:show, :edit, :update, :destroy, :activate, :deactivate]

  def index
    @question_banks = policy_scope(QuestionBank)
                       .includes(:competency)
                       .then { |q| params[:type].present? ? q.by_type(params[:type]) : q }
                       .then { |q| params[:difficulty].present? ? q.by_difficulty(params[:difficulty]) : q }
                       .then { |q| params[:search].present? ? q.search(params[:search]) : q }
                       .then { |q| params[:active] == "false" ? q.inactive : q.active }
                       .order(updated_at: :desc)
                       .page(params[:page])
  end

  def show
    authorize @question_bank
  end

  def new
    @question_bank = QuestionBank.new
    authorize @question_bank
  end

  def edit
    authorize @question_bank
  end

  def create
    @question_bank = QuestionBank.new(question_bank_params)
    authorize @question_bank

    if @question_bank.save
      redirect_to question_banks_path, notice: "Question was created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @question_bank

    if @question_bank.update(question_bank_params)
      redirect_to question_banks_path, notice: "Question was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @question_bank

    # Soft delete by deactivating instead of destroying
    @question_bank.deactivate!
    redirect_to question_banks_path, notice: "Question was archived."
  end

  def activate
    authorize @question_bank, :update?

    @question_bank.activate!
    redirect_to question_banks_path, notice: "Question was activated."
  end

  def deactivate
    authorize @question_bank, :update?

    @question_bank.deactivate!
    redirect_to question_banks_path, notice: "Question was deactivated."
  end

  private

  def set_question_bank
    @question_bank = QuestionBank.find(params[:id])
  end

  def question_bank_params
    params.require(:question_bank).permit(
      :question,
      :guidance,
      :question_type,
      :difficulty,
      :competency_id,
      :tags,
      :active
    )
  end
end
