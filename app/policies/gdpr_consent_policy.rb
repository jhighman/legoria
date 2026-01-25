# frozen_string_literal: true

class GdprConsentPolicy < ApplicationPolicy
  def index?
    recruiter? || admin?
  end

  def show?
    same_organization? && (recruiter? || admin?)
  end

  def create?
    recruiter? || admin?
  end

  def withdraw?
    same_organization? && (recruiter? || admin?) && record.active?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organization: user.organization)
    end
  end
end
