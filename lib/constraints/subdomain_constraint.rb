# frozen_string_literal: true

module Constraints
  # SubdomainConstraint validates that a request has a valid organization subdomain.
  # Used in routes.rb to conditionally route career site requests.
  #
  # Usage in config/routes.rb:
  #   constraints Constraints::SubdomainConstraint.new do
  #     # career site routes
  #   end
  #
  class SubdomainConstraint
    RESERVED_SUBDOMAINS = %w[
      www admin api mail ftp smtp pop imap
      app dashboard portal login signin signup
      assets static cdn images js css
      help support docs blog news
      staging dev test demo sandbox
    ].freeze

    def matches?(request)
      subdomain = extract_subdomain(request)

      return false if subdomain.blank?
      return false if reserved_subdomain?(subdomain)

      Organization.kept.exists?(subdomain: subdomain)
    end

    private

    def extract_subdomain(request)
      # Handle cases where subdomain might be nil or multiple levels
      subdomain = request.subdomain

      # If subdomain includes multiple parts (e.g., "foo.bar"), use only the first part
      subdomain = subdomain.split(".").first if subdomain.present? && subdomain.include?(".")

      subdomain&.downcase
    end

    def reserved_subdomain?(subdomain)
      RESERVED_SUBDOMAINS.include?(subdomain.downcase)
    end
  end
end
