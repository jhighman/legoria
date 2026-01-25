# frozen_string_literal: true

class SelfScheduleController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_self_schedule
  layout "public"

  def show
    if @self_schedule.expired?
      render :expired
    elsif @self_schedule.scheduled?
      render :confirmed
    elsif @self_schedule.cancelled?
      render :cancelled
    else
      @available_slots = @self_schedule.available_slots_list
    end
  end

  def select_slot
    slot_time = Time.zone.parse(params[:slot_time])

    @self_schedule.schedule_slot!(slot_time)
    redirect_to self_schedule_confirmation_path(@self_schedule.token)
  rescue StandardError => e
    redirect_to self_schedule_path(@self_schedule.token), alert: e.message
  end

  def confirmation
    unless @self_schedule.scheduled?
      redirect_to self_schedule_path(@self_schedule.token)
    end
  end

  private

  def set_self_schedule
    @self_schedule = InterviewSelfSchedule.find_by!(token: params[:token])
    @interview = @self_schedule.interview
    @candidate = @interview.candidate
    @job = @interview.job
  end
end
