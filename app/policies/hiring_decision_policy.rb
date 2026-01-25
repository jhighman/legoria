# frozen_string_literal: true

class HiringDecisionPolicy < ApplicationPolicy
  def index?
    user.present? && can_view_decisions?
  end

  def show?
    same_organization? && can_view_decisions?
  end

  def create?
    same_organization? && can_create_decisions?
  end

  def approve?
    same_organization? && can_approve_decisions?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.where(organization_id: user.organization_id)
      elsif user.recruiter?
        scope.where(organization_id: user.organization_id)
      elsif user.hiring_manager?
        # Hiring managers see decisions for jobs they manage
        job_ids = Job.where(hiring_manager_id: user.id).pluck(:id)
        scope.where(organization_id: user.organization_id)
              .joins(:application)
              .where(applications: { job_id: job_ids })
      else
        scope.none
      end
    end
  end

  private

  def can_view_decisions?
    admin? || recruiter? || hiring_manager?
  end

  def can_create_decisions?
    admin? || recruiter? || hiring_manager_for_job?
  end

  def can_approve_decisions?
    return false if record.decided_by_id == user.id # Can't approve own decisions

    admin? || hiring_manager_for_job?
  end

  def hiring_manager_for_job?
    return false unless record.respond_to?(:application)

    record.application&.job&.hiring_manager_id == user.id
  end
end
