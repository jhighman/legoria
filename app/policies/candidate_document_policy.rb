# frozen_string_literal: true

class CandidateDocumentPolicy < ApplicationPolicy
  def index?
    can_view_candidate?
  end

  def show?
    can_view_candidate? && record.visible_to_employer?
  end

  def create?
    # Documents are created by candidates in their portal
    false
  end

  def update?
    can_manage_candidate?
  end

  def destroy?
    can_manage_candidate?
  end

  class Scope < Scope
    def resolve
      scope.joins(:candidate)
            .where(candidates: { organization_id: user.organization_id })
            .visible
    end
  end

  private

  def can_view_candidate?
    admin? || recruiter? || hiring_manager_for_candidate?
  end

  def can_manage_candidate?
    admin? || recruiter?
  end

  def hiring_manager_for_candidate?
    return false unless hiring_manager?

    record.candidate.applications.joins(:job)
          .where(jobs: { hiring_manager_id: user.id })
          .exists?
  end
end
