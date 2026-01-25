# frozen_string_literal: true

class ScorecardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_interview
  before_action :set_scorecard, only: [:show, :edit, :update, :submit]
  before_action :set_participant, only: [:show, :edit, :update, :submit]

  def show
    authorize @scorecard
  end

  def edit
    authorize @scorecard

    unless @scorecard.editable?
      redirect_to interview_scorecard_path(@interview), alert: "This scorecard has already been submitted."
    end
  end

  def update
    authorize @scorecard

    unless @scorecard.editable?
      redirect_to interview_scorecard_path(@interview), alert: "This scorecard has already been submitted."
      return
    end

    if @scorecard.update(scorecard_params)
      if params[:commit] == "Submit"
        redirect_to submit_interview_scorecard_path(@interview)
      else
        redirect_to interview_scorecard_path(@interview), notice: "Scorecard saved successfully."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def submit
    authorize @scorecard

    result = SubmitScorecardService.call(
      scorecard: @scorecard,
      submitted_by: current_user
    )

    if result.success?
      redirect_to interview_scorecard_path(@interview), notice: "Scorecard submitted successfully."
    else
      flash.now[:alert] = result.failure.is_a?(String) ? result.failure : "Unable to submit scorecard."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_interview
    @interview = Interview.find(params[:interview_id])
  end

  def set_scorecard
    @participant = @interview.interview_participants.find_by(user: current_user)

    if @participant
      @scorecard = @participant.scorecard || create_scorecard
    else
      # For viewing other scorecards (hiring managers, recruiters)
      @scorecard = @interview.scorecards.find_by(visible_to_team: true)
      render_not_found unless @scorecard
    end
  end

  def set_participant
    @participant ||= @scorecard.interview_participant
  end

  def create_scorecard
    template = ScorecardTemplate.find_for_interview(@interview)

    @participant.create_scorecard!(
      organization: @interview.organization,
      interview: @interview,
      scorecard_template: template
    )
  end

  def scorecard_params
    params.require(:scorecard).permit(
      :overall_recommendation,
      :summary,
      :strengths,
      :concerns,
      scorecard_responses_attributes: [
        :id, :scorecard_template_item_id, :rating, :yes_no_value, :text_value, :select_value, :notes
      ]
    )
  end

  def render_not_found
    redirect_to @interview, alert: "Scorecard not found."
  end
end
