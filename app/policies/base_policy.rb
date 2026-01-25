# frozen_string_literal: true

class BasePolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user_signed_in?
  end

  def show?
    user_signed_in? && same_organization?
  end

  def create?
    user_signed_in?
  end

  def new?
    create?
  end

  def update?
    user_signed_in? && same_organization?
  end

  def edit?
    update?
  end

  def destroy?
    user_signed_in? && same_organization? && admin?
  end

  private

  def user_signed_in?
    user.present?
  end

  def admin?
    user&.admin?
  end

  def recruiter?
    user&.recruiter? || admin?
  end

  def hiring_manager?
    user&.hiring_manager? || admin?
  end

  def same_organization?
    return false unless user && record
    return true unless record.respond_to?(:organization_id)

    record.organization_id == user.organization_id
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if scope.column_names.include?("organization_id")
        scope.where(organization_id: user.organization_id)
      else
        scope.all
      end
    end
  end
end
