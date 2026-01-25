# frozen_string_literal: true

class CandidateSelfScheduleMailer < ApplicationMailer
  def invitation(self_schedule)
    @self_schedule = self_schedule
    @interview = self_schedule.interview
    @candidate = @interview.candidate
    @job = @interview.job
    @scheduling_url = self_schedule_url(self_schedule.token)

    mail(
      to: @candidate.email,
      subject: "Schedule Your Interview for #{@job.title}"
    )
  end

  def confirmation(self_schedule)
    @self_schedule = self_schedule
    @interview = self_schedule.interview
    @candidate = @interview.candidate
    @job = @interview.job

    mail(
      to: @candidate.email,
      subject: "Interview Confirmed - #{@job.title}"
    )
  end

  def reminder(self_schedule)
    @self_schedule = self_schedule
    @interview = self_schedule.interview
    @candidate = @interview.candidate
    @job = @interview.job
    @scheduling_url = self_schedule_url(self_schedule.token)

    mail(
      to: @candidate.email,
      subject: "Reminder: Schedule Your Interview for #{@job.title}"
    )
  end

  private

  def self_schedule_url(token)
    # Generate the public self-schedule URL
    "#{root_url}schedule/#{token}"
  end
end
