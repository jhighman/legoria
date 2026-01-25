# frozen_string_literal: true

class InterviewPolicy < BasePolicy
  def index?
    user_signed_in?
  end

  def show?
    user_signed_in? && (same_organization? || participant?)
  end

  def create?
    same_organization? && (recruiter? || hiring_manager?)
  end

  def new?
    create?
  end

  def update?
    same_organization? && (recruiter? || hiring_manager? || scheduler?)
  end

  def edit?
    update?
  end

  def destroy?
    same_organization? && (recruiter? || admin?)
  end

  def cancel?
    same_organization? && (recruiter? || hiring_manager? || scheduler?)
  end

  def confirm?
    update?
  end

  def complete?
    update?
  end

  def mark_no_show?
    update?
  end

  # Can view the candidate's details for interview prep
  def view_candidate?
    show? && interviewer?
  end

  # Can submit feedback/scorecard
  def submit_feedback?
    show? && interviewer? && record.completed?
  end

  private

  def scheduler?
    record.scheduled_by_id == user.id
  end

  def participant?
    record.interview_participants.exists?(user_id: user.id)
  end

  def interviewer?
    record.interview_participants.where(user_id: user.id, role: %w[lead interviewer]).exists?
  end

  class Scope < BasePolicy::Scope
    def resolve
      base = scope.where(organization_id: user.organization_id)

      if user.admin? || user.recruiter?
        # Admins and recruiters can see all interviews in their org
        base
      elsif user.hiring_manager?
        # Hiring managers see interviews for jobs they manage + their own interviews
        managed_job_ids = Job.where(hiring_manager_id: user.id).pluck(:id)
        base.where(job_id: managed_job_ids)
            .or(base.joins(:interview_participants).where(interview_participants: { user_id: user.id }))
      else
        # Other users only see interviews they're participating in
        base.joins(:interview_participants)
            .where(interview_participants: { user_id: user.id })
      end
    end
  end
end
