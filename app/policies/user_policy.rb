# frozen_string_literal: true

class UserPolicy < BasePolicy
  def index?
    recruiter?
  end

  def show?
    super && (admin? || record == user)
  end

  def create?
    admin?
  end

  def update?
    admin? || record == user
  end

  def destroy?
    admin? && record != user
  end

  def deactivate?
    admin? && record != user
  end

  def activate?
    admin?
  end

  def manage_roles?
    admin?
  end

  class Scope < BasePolicy::Scope
    def resolve
      scope.where(organization_id: user.organization_id)
    end
  end
end
