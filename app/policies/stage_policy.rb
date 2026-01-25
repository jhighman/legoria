# frozen_string_literal: true

class StagePolicy < BasePolicy
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
    admin?
  end

  def destroy?
    admin? && !record.is_default?
  end

  def reorder?
    admin?
  end

  class Scope < BasePolicy::Scope
    def resolve
      scope.where(organization_id: user.organization_id)
    end
  end
end
