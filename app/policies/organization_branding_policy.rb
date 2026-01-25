# frozen_string_literal: true

class OrganizationBrandingPolicy < ApplicationPolicy
  def show?
    admin?
  end

  def edit?
    admin?
  end

  def update?
    admin?
  end
end
