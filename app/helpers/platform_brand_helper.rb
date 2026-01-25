# frozen_string_literal: true

# PlatformBrandHelper provides view helpers for accessing branding values
# with automatic fallback from organization branding to platform defaults.
#
# Fallback chain: Organization branding → Platform branding → Hardcoded defaults
#
# Usage in views:
#   <%= platform_name %>                    # => Organization name or "Ledgoria"
#   <%= platform_logo_url %>                # => Organization logo or platform logo
#   <%= brand_primary_color %>              # => "#0d6efd" (from org or platform)
#   <%= email_from_address %>               # => Custom from address or platform default
#
module PlatformBrandHelper
  # Core identity - uses organization name when in org context, platform name otherwise
  def platform_name
    current_organization&.name.presence || PlatformBrand.name
  end

  def platform_tagline
    current_branding&.company_tagline.presence || PlatformBrand.tagline
  end

  def platform_domain
    current_organization&.domain.presence || PlatformBrand.domain
  end

  # Visual identity
  def platform_logo_url
    if current_branding&.logo&.attached?
      url_for(current_branding.logo)
    else
      asset_path(PlatformBrand.logo_path)
    end
  end

  def platform_favicon_url
    if current_branding&.favicon&.attached?
      url_for(current_branding.favicon)
    else
      asset_path(PlatformBrand.favicon_path)
    end
  end

  def brand_primary_color
    current_branding&.primary_color.presence || PlatformBrand.primary_color
  end

  def brand_secondary_color
    current_branding&.secondary_color.presence || PlatformBrand.secondary_color
  end

  def brand_accent_color
    current_branding&.accent_color.presence || PlatformBrand.accent_color
  end

  # Typography
  def brand_font_family
    current_branding&.font_family.presence || "system-ui, -apple-system, sans-serif"
  end

  def brand_heading_font_family
    current_branding&.heading_font_family.presence || brand_font_family
  end

  def brand_google_fonts_url
    current_branding&.google_fonts_url
  end

  # Contact
  def platform_support_email
    current_branding&.support_email.presence || PlatformBrand.support_email
  end

  def email_from_address
    if current_branding&.custom_from_address.present? && current_branding&.email_domain_verified?
      current_branding.custom_from_address
    else
      PlatformBrand.default_from_email
    end
  end

  # Email branding
  def email_footer_text
    current_branding&.email_footer_text.presence || "Sent via #{PlatformBrand.name}"
  end

  def show_powered_by?
    current_branding&.show_powered_by? != false
  end

  def powered_by_text
    PlatformBrand.powered_by_text
  end

  # CSS variables for dynamic styling
  def brand_css_variables
    <<~CSS.html_safe
      :root {
        --brand-primary: #{brand_primary_color};
        --brand-secondary: #{brand_secondary_color};
        --brand-accent: #{brand_accent_color};
        --brand-font-family: #{brand_font_family};
        --brand-heading-font-family: #{brand_heading_font_family};
      }
    CSS
  end

  # URL helpers
  def platform_url
    PlatformBrand.url
  end

  def platform_careers_suffix
    PlatformBrand.careers_subdomain_suffix
  end

  private

  def current_branding
    @current_branding ||= current_organization&.branding
  end

  def current_organization
    return Current.organization if defined?(Current) && Current.respond_to?(:organization)

    nil
  end
end
