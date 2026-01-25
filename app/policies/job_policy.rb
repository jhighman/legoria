# frozen_string_literal: true

class JobPolicy < BasePolicy
  def index?
    user_signed_in?
  end

  def show?
    user_signed_in? && same_organization? && can_view_job?
  end

  def create?
    recruiter? || admin?
  end

  def update?
    same_organization? && (admin? || owner? || recruiter_owner?)
  end

  def destroy?
    same_organization? && admin?
  end

  # Workflow actions
  def submit_for_approval?
    same_organization? && record.draft? && (admin? || recruiter_owner?)
  end

  def approve?
    same_organization? && record.pending_approval? && can_approve?
  end

  def reject?
    approve?
  end

  def put_on_hold?
    same_organization? && record.open? && (admin? || recruiter_owner?)
  end

  def close?
    same_organization? && (record.open? || record.on_hold?) && (admin? || recruiter_owner?)
  end

  def reopen?
    same_organization? && (record.closed? || record.on_hold?) && (admin? || recruiter_owner?)
  end

  def duplicate?
    same_organization? && (recruiter? || admin?)
  end

  class Scope < BasePolicy::Scope
    def resolve
      base_scope = scope.where(organization_id: user.organization_id)

      if user.admin? || user.recruiter?
        base_scope
      elsif user.hiring_manager?
        base_scope.where(hiring_manager_id: user.id)
      else
        base_scope.none
      end
    end
  end

  private

  def can_view_job?
    admin? || recruiter? || owner? || recruiter_owner?
  end

  def owner?
    record.hiring_manager_id == user.id
  end

  def recruiter_owner?
    record.recruiter_id == user.id
  end

  def can_approve?
    return true if admin?

    # Hiring manager can approve jobs assigned to them
    user.hiring_manager? && record.hiring_manager_id == user.id
  end
end
