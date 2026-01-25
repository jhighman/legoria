# frozen_string_literal: true

class InterviewerPrepController < ApplicationController
  before_action :set_interview

  def show
    authorize @interview, :show?

    @interview_kit = InterviewKit.find_for_interview(@interview)
    @application = @interview.application
    @candidate = @application.candidate
    @scorecards = @interview.scorecards.completed.visible.includes(:interview_participant)
    @previous_interviews = @application.interviews
                                        .where.not(id: @interview.id)
                                        .completed
                                        .includes(:interview_participants)
                                        .order(scheduled_at: :desc)

    # Load the interviewer's scorecard if they have one
    participant = @interview.interview_participants.find_by(user: current_user)
    @my_scorecard = participant&.scorecard
  end

  private

  def set_interview
    @interview = Interview.find(params[:interview_id])
  end
end
