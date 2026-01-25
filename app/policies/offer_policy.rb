# frozen_string_literal: true

class OfferPolicy < ApplicationPolicy
  def index?
    recruiter? || admin? || hiring_manager?
  end

  def show?
    same_organization? && (recruiter? || admin? || hiring_manager?)
  end

  def create?
    same_organization? && (recruiter? || admin?)
  end

  def update?
    same_organization? && (recruiter? || admin?) && record.can_edit?
  end

  def destroy?
    same_organization? && admin? && record.draft?
  end

  def submit_for_approval?
    same_organization? && (recruiter? || admin?) && record.can_submit_for_approval?
  end

  def send_offer?
    same_organization? && (recruiter? || admin?) && record.can_send?
  end

  def withdraw?
    same_organization? && (recruiter? || admin?) && !record.accepted? && !record.declined?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organization: user.organization)
    end
  end
end
