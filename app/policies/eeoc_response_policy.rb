# frozen_string_literal: true

class EeocResponsePolicy < ApplicationPolicy
  # EEOC data is sensitive - only admin can view individual responses
  def index?
    admin?
  end

  def show?
    same_organization? && admin?
  end

  # Creation is handled via public form (no auth required)
  def create?
    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organization: user.organization)
    end
  end
end
