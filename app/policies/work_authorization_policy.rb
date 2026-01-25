# frozen_string_literal: true

class WorkAuthorizationPolicy < BasePolicy
  def index?
    recruiter? || admin?
  end

  def show?
    same_organization? && can_view?
  end

  def create?
    same_organization? && (recruiter? || admin?)
  end

  def update?
    same_organization? && (recruiter? || admin?)
  end

  def destroy?
    false # Work authorization records cannot be deleted for compliance
  end

  def expiring?
    recruiter? || admin?
  end

  class Scope < BasePolicy::Scope
    def resolve
      scope.where(organization_id: user.organization_id)
    end
  end

  private

  def can_view?
    admin? || recruiter?
  end
end
