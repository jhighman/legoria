# frozen_string_literal: true

class RolePolicy < BasePolicy
  def index?
    admin?
  end

  def show?
    admin?
  end

  def create?
    admin? && !record.system_role?
  end

  def update?
    admin? && !record.system_role?
  end

  def destroy?
    admin? && !record.system_role?
  end

  def manage_permissions?
    admin?
  end

  class Scope < BasePolicy::Scope
    def resolve
      scope.where(organization_id: user.organization_id)
    end
  end
end
