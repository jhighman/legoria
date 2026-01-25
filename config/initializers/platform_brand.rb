# frozen_string_literal: true

# PlatformBrand provides centralized access to platform-level branding configuration.
# All values can be overridden via environment variables for easy rebranding.
#
# Usage:
#   PlatformBrand.name          # => "Ledgoria"
#   PlatformBrand.domain        # => "ledgoria.com"
#   PlatformBrand.logo_path     # => "ledgoria-logo.svg"
#
# Environment variables:
#   PLATFORM_NAME, PLATFORM_DOMAIN, PLATFORM_LOGO, PLATFORM_PRIMARY_COLOR,
#   PLATFORM_SECONDARY_COLOR, PLATFORM_SUPPORT_EMAIL, PLATFORM_TAGLINE
#
class PlatformBrand
  class << self
    # Core identity
    def name
      ENV.fetch("PLATFORM_NAME", "Ledgoria")
    end

    def domain
      ENV.fetch("PLATFORM_DOMAIN", "ledgoria.com")
    end

    def tagline
      ENV.fetch("PLATFORM_TAGLINE", "Compliance-first hiring")
    end

    # Visual identity
    def logo_path
      ENV.fetch("PLATFORM_LOGO", "ledgoria-logo.svg")
    end

    def favicon_path
      ENV.fetch("PLATFORM_FAVICON", "favicon.ico")
    end

    def primary_color
      ENV.fetch("PLATFORM_PRIMARY_COLOR", "#0d6efd")
    end

    def secondary_color
      ENV.fetch("PLATFORM_SECONDARY_COLOR", "#6c757d")
    end

    def accent_color
      ENV.fetch("PLATFORM_ACCENT_COLOR", "#0dcaf0")
    end

    # Contact
    def support_email
      ENV.fetch("PLATFORM_SUPPORT_EMAIL", "support@#{domain}")
    end

    def default_from_email
      ENV.fetch("PLATFORM_FROM_EMAIL", "noreply@#{domain}")
    end

    # URLs
    def url
      ENV.fetch("PLATFORM_URL", "https://#{domain}")
    end

    def careers_subdomain_suffix
      ".#{domain}"
    end

    # Helper methods
    def powered_by_text
      "Powered by #{name}"
    end

    def copyright_text(year = Time.current.year)
      "#{year} #{name}. All rights reserved."
    end

    # Returns a hash of all brand settings for easy access
    def to_h
      {
        name: name,
        domain: domain,
        tagline: tagline,
        logo_path: logo_path,
        favicon_path: favicon_path,
        primary_color: primary_color,
        secondary_color: secondary_color,
        accent_color: accent_color,
        support_email: support_email,
        default_from_email: default_from_email,
        url: url
      }
    end
  end
end
