# frozen_string_literal: true

class QuestionBankPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    same_organization?
  end

  def create?
    same_organization? && can_manage_questions?
  end

  def update?
    same_organization? && can_manage_questions?
  end

  def destroy?
    same_organization? && can_manage_questions?
  end

  class Scope < Scope
    def resolve
      scope.where(organization_id: user.organization_id)
    end
  end

  private

  def can_manage_questions?
    admin? || recruiter? || hiring_manager?
  end
end
