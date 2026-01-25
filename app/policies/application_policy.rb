# frozen_string_literal: true

class ApplicationPolicy < BasePolicy
  def index?
    user_signed_in?
  end

  def show?
    user_signed_in? && same_organization? && can_view?
  end

  def create?
    same_organization? && (recruiter? || admin?) && job_open?
  end

  def update?
    same_organization? && (admin? || recruiter? || hiring_manager_for_job?)
  end

  def destroy?
    same_organization? && admin?
  end

  def move_stage?
    update?
  end

  def reject?
    update? && record.active?
  end

  def withdraw?
    update? && record.active?
  end

  def star?
    update?
  end

  def unstar?
    star?
  end

  def rate?
    update?
  end

  class Scope < BasePolicy::Scope
    def resolve
      base_scope = scope.where(organization_id: user.organization_id)

      if user.admin? || user.recruiter?
        base_scope
      elsif user.hiring_manager?
        base_scope.joins(:job).where(jobs: { hiring_manager_id: user.id })
      else
        base_scope.none
      end
    end
  end

  private

  def can_view?
    admin? || recruiter? || hiring_manager_for_job?
  end

  def job_open?
    record.job&.open?
  end

  def hiring_manager_for_job?
    user.hiring_manager? && record.job&.hiring_manager_id == user.id
  end
end
