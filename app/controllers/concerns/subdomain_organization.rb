# frozen_string_literal: true

# SubdomainOrganization concern resolves the current organization
# from the request subdomain for career site controllers.
#
# Resolution order:
# 1. Custom domain (if custom_domain matches request host)
# 2. Subdomain (if subdomain matches request subdomain)
# 3. Fallback to first organization (development only)
#
# Usage:
#   class CareerSiteController < ApplicationController
#     include SubdomainOrganization
#   end
#
module SubdomainOrganization
  extend ActiveSupport::Concern

  included do
    before_action :resolve_organization_from_subdomain
    helper_method :career_site_organization, :current_branding
  end

  private

  def resolve_organization_from_subdomain
    @organization = find_organization_by_domain || find_organization_by_subdomain || fallback_organization

    if @organization.nil?
      render_organization_not_found
      return
    end

    # Set Current context for helpers
    Current.organization = @organization
  end

  def find_organization_by_domain
    host = request.host.downcase
    Organization.kept.find_by(domain: host)
  end

  def find_organization_by_subdomain
    subdomain = extract_subdomain
    return nil if subdomain.blank?

    Organization.kept.find_by(subdomain: subdomain)
  end

  def extract_subdomain
    subdomain = request.subdomain
    return nil if subdomain.blank?

    # Handle multiple subdomain levels
    subdomain = subdomain.split(".").first if subdomain.include?(".")

    subdomain.downcase
  end

  def fallback_organization
    # In development/test, fall back to first organization for convenience
    return nil unless Rails.env.development? || Rails.env.test?

    Organization.kept.first
  end

  def render_organization_not_found
    render file: Rails.root.join("public", "404.html"), status: :not_found, layout: false
  end

  def career_site_organization
    @organization
  end

  def current_branding
    @current_branding ||= @organization&.branding
  end

  # Alias for compatibility with PlatformBrandHelper
  def current_organization
    @organization
  end
end
