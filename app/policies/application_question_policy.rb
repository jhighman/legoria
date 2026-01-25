# frozen_string_literal: true

class ApplicationQuestionPolicy < ApplicationPolicy
  def index?
    can_manage_jobs?
  end

  def show?
    can_manage_jobs?
  end

  def create?
    can_manage_jobs?
  end

  def update?
    can_manage_jobs?
  end

  def destroy?
    can_manage_jobs?
  end

  class Scope < Scope
    def resolve
      if user.admin? || user.recruiter?
        scope.joins(:job).where(jobs: { organization_id: user.organization_id })
      else
        scope.none
      end
    end
  end

  private

  def can_manage_jobs?
    admin? || recruiter?
  end
end
