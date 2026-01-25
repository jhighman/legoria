# frozen_string_literal: true

class ScorecardPolicy < BasePolicy
  # Visibility Rules:
  # - Draft scorecards: Only visible to author
  # - Submitted scorecards: Visible to hiring manager + recruiter + admin
  # - All submitted: Visible to all interviewers for that application (after their own submission)

  def show?
    return false unless user_signed_in? && same_organization?

    # Author can always see their own
    return true if author?

    # Draft scorecards only visible to author
    return false if record.draft?

    # Admins, recruiters, hiring managers can see submitted scorecards
    return true if admin? || recruiter?
    return true if hiring_manager_for_job?

    # Other interviewers can see after submitting their own
    interviewer_with_submitted_scorecard?
  end

  def edit?
    return false unless user_signed_in? && same_organization?

    # Only author can edit
    return false unless author?

    # Can only edit drafts
    record.draft?
  end

  def update?
    edit?
  end

  def submit?
    edit?
  end

  private

  def author?
    record.interview_participant.user_id == user.id
  end

  def hiring_manager_for_job?
    record.job.hiring_manager_id == user.id
  end

  def recruiter_for_job?
    record.job.recruiter_id == user.id
  end

  def interviewer_with_submitted_scorecard?
    # Check if user is an interviewer for this application
    application = record.interview.application
    user_interviews = Interview.for_user(user.id)
                               .where(application_id: application.id)

    return false unless user_interviews.any?

    # Check if they've submitted their own scorecard for any interview on this application
    user_scorecard_ids = InterviewParticipant.where(user_id: user.id, interview_id: user_interviews.pluck(:id))
                                             .pluck(:id)

    Scorecard.where(interview_participant_id: user_scorecard_ids, status: %w[submitted locked]).exists?
  end

  class Scope < BasePolicy::Scope
    def resolve
      base = scope.where(organization_id: user.organization_id)

      if user.admin? || user.recruiter?
        # Admins and recruiters see all submitted + their own drafts
        base.where(visible_to_team: true)
            .or(base.joins(:interview_participant).where(interview_participants: { user_id: user.id }))
      elsif user.hiring_manager?
        # Hiring managers see submitted for their jobs + their own
        managed_job_ids = Job.where(hiring_manager_id: user.id).pluck(:id)
        base.joins(:interview)
            .where(interviews: { job_id: managed_job_ids }, visible_to_team: true)
            .or(base.joins(:interview_participant).where(interview_participants: { user_id: user.id }))
      else
        # Regular interviewers only see their own
        base.joins(:interview_participant)
            .where(interview_participants: { user_id: user.id })
      end
    end
  end
end
