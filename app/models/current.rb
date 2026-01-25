# frozen_string_literal: true

# Current provides thread-safe, request-scoped storage for tenant context.
# Set Current.organization in ApplicationController to scope all queries.
#
# Usage:
#   Current.organization = Organization.find_by!(subdomain: request.subdomain)
#   Job.all # Automatically scoped to Current.organization
#
class Current < ActiveSupport::CurrentAttributes
  attribute :organization
  attribute :user
  attribute :request_id
  attribute :user_agent
  attribute :ip_address

  # Reset is called automatically at the end of each request
  resets { Time.zone = "UTC" }

  def organization=(org)
    super
    Time.zone = org&.timezone || "UTC"
  end

  # Convenience method to check if organization context is set
  def organization?
    organization.present?
  end

  # Convenience method to check if user is authenticated
  def user?
    user.present?
  end
end
