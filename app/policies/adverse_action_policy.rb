# frozen_string_literal: true

class AdverseActionPolicy < ApplicationPolicy
  def index?
    recruiter? || admin?
  end

  def show?
    same_organization? && (recruiter? || admin?)
  end

  def create?
    same_organization? && (recruiter? || admin?)
  end

  def update?
    same_organization? && (recruiter? || admin?) && record.draft?
  end

  def send_pre_adverse?
    same_organization? && (recruiter? || admin?) && record.can_send_pre_adverse?
  end

  def record_dispute?
    same_organization? && (recruiter? || admin?) && record.waiting_period?
  end

  def send_final?
    same_organization? && (recruiter? || admin?) && record.can_send_final?
  end

  def cancel?
    same_organization? && admin? && !record.completed?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organization: user.organization)
    end
  end
end
