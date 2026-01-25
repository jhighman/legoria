# frozen_string_literal: true

class CandidatePolicy < BasePolicy
  def index?
    user_signed_in?
  end

  def show?
    user_signed_in? && same_organization?
  end

  def create?
    recruiter? || admin?
  end

  def update?
    same_organization? && (admin? || recruiter?)
  end

  def destroy?
    same_organization? && admin?
  end

  def merge?
    same_organization? && admin?
  end

  def add_note?
    same_organization? && user_signed_in?
  end

  def upload_resume?
    same_organization? && (admin? || recruiter?)
  end

  class Scope < BasePolicy::Scope
    def resolve
      if user.admin? || user.recruiter?
        scope.where(organization_id: user.organization_id)
      elsif user.hiring_manager?
        # HMs can only see candidates who have applied to their jobs
        scope.where(organization_id: user.organization_id)
             .joins(:applications)
             .joins("INNER JOIN jobs ON jobs.id = applications.job_id")
             .where(jobs: { hiring_manager_id: user.id })
             .distinct
      else
        scope.none
      end
    end
  end
end
