# frozen_string_literal: true

class OrganizationPolicy < BasePolicy
  def show?
    user_signed_in? && record == user.organization
  end

  def update?
    admin? && record == user.organization
  end

  def manage_settings?
    admin?
  end

  def manage_billing?
    admin?
  end

  class Scope < BasePolicy::Scope
    def resolve
      scope.where(id: user.organization_id)
    end
  end
end
