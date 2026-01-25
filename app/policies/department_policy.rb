# frozen_string_literal: true

class DepartmentPolicy < BasePolicy
  def index?
    user_signed_in?
  end

  def show?
    user_signed_in? && same_organization?
  end

  def create?
    admin?
  end

  def update?
    admin? || department_manager?
  end

  def destroy?
    admin?
  end

  private

  def department_manager?
    record.default_hiring_manager_id == user.id
  end

  class Scope < BasePolicy::Scope
    def resolve
      scope.where(organization_id: user.organization_id)
    end
  end
end
