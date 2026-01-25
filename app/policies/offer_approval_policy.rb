# frozen_string_literal: true

class OfferApprovalPolicy < ApplicationPolicy
  def approve?
    record.approver == user && record.pending?
  end

  def reject?
    record.approver == user && record.pending?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:offer).where(offers: { organization_id: user.organization_id })
    end
  end
end
