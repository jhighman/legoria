# frozen_string_literal: true

# OrganizationScoped provides automatic tenant scoping for models.
#
# Include this concern in any model that belongs to an organization:
#
#   class Job < ApplicationRecord
#     include OrganizationScoped
#   end
#
# This will:
# - Add belongs_to :organization association
# - Set default_scope to filter by Current.organization
# - Auto-assign organization_id before validation
# - Validate organization_id presence
#
module OrganizationScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :organization

    # Automatically scope queries to current organization
    default_scope lambda {
      if Current.organization
        where(organization_id: Current.organization.id)
      else
        all
      end
    }

    # Auto-assign organization from Current context
    before_validation :set_organization, on: :create

    validates :organization_id, presence: true
  end

  private

  def set_organization
    self.organization_id ||= Current.organization&.id
  end

  class_methods do
    # Query across all organizations (use with caution)
    def unscoped_all
      unscoped.all
    end

    # Find record in specific organization
    def find_in_organization(org, id)
      unscoped.where(organization_id: org.id).find(id)
    end
  end
end
