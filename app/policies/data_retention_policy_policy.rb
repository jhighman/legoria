# frozen_string_literal: true

class DataRetentionPolicyPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    same_organization? && admin?
  end

  def create?
    same_organization? && admin?
  end

  def update?
    same_organization? && admin?
  end

  def destroy?
    same_organization? && admin?
  end

  def toggle_active?
    same_organization? && admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organization: user.organization)
    end
  end
end
