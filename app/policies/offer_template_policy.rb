# frozen_string_literal: true

class OfferTemplatePolicy < ApplicationPolicy
  def index?
    recruiter? || admin?
  end

  def show?
    same_organization? && (recruiter? || admin?)
  end

  def create?
    same_organization? && admin?
  end

  def update?
    same_organization? && admin?
  end

  def destroy?
    same_organization? && admin? && record.offers.none?
  end

  def duplicate?
    same_organization? && admin?
  end

  def make_default?
    same_organization? && admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organization: user.organization)
    end
  end
end
