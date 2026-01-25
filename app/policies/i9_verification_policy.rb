# frozen_string_literal: true

class I9VerificationPolicy < BasePolicy
  def index?
    recruiter? || admin?
  end

  def show?
    same_organization? && can_view?
  end

  def create?
    same_organization? && (recruiter? || admin?)
  end

  def update?
    same_organization? && (recruiter? || admin?)
  end

  def destroy?
    false # I-9 records cannot be deleted for compliance
  end

  def section2?
    same_organization? && (recruiter? || admin?) && record.section1_complete?
  end

  def complete_section2?
    section2?
  end

  def section3?
    same_organization? && (recruiter? || admin?) && record.verified?
  end

  def complete_section3?
    section3?
  end

  def pending?
    recruiter? || admin?
  end

  def overdue?
    recruiter? || admin?
  end

  class Scope < BasePolicy::Scope
    def resolve
      base_scope = scope.where(organization_id: user.organization_id)

      if user.admin? || user.recruiter?
        base_scope
      elsif user.hiring_manager?
        base_scope.joins(application: :job).where(jobs: { hiring_manager_id: user.id })
      else
        base_scope.none
      end
    end
  end

  private

  def can_view?
    admin? || recruiter? || hiring_manager_for_application?
  end

  def hiring_manager_for_application?
    return false unless user.hiring_manager?

    record.application&.job&.hiring_manager_id == user.id
  end
end
