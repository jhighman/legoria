# frozen_string_literal: true

class DeletionRequestPolicy < ApplicationPolicy
  def index?
    recruiter? || admin?
  end

  def show?
    same_organization? && (recruiter? || admin?)
  end

  def create?
    recruiter? || admin?
  end

  def verify?
    same_organization? && (recruiter? || admin?) && !record.identity_verified?
  end

  def process_request?
    same_organization? && admin? && record.can_process?
  end

  def reject?
    same_organization? && admin? && (record.pending? || record.in_progress?)
  end

  def place_hold?
    same_organization? && admin? && !record.legal_hold? && !record.completed?
  end

  def remove_hold?
    same_organization? && admin? && record.legal_hold?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organization: user.organization)
    end
  end
end
