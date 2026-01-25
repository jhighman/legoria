# frozen_string_literal: true

class ReportPolicy < BasePolicy
  # Basic reports - accessible to all authenticated users
  def index?
    user_signed_in?
  end

  def time_to_hire?
    user_signed_in?
  end

  def sources?
    user_signed_in?
  end

  def pipeline?
    user_signed_in?
  end

  def operational?
    recruiter? || admin?
  end

  def recruiter_productivity?
    recruiter? || admin?
  end

  def requisition_aging?
    recruiter? || admin?
  end

  # Diversity reports - admin only
  def eeoc?
    admin?
  end

  def diversity?
    admin?
  end

  def adverse_impact?
    admin?
  end

  # Export permissions
  def export?
    user_signed_in?
  end

  def export_pdf?
    user_signed_in?
  end

  def export_diversity_pdf?
    admin?
  end

  class Scope < BasePolicy::Scope
    def resolve
      scope
    end
  end
end
