# frozen_string_literal: true

# Base mailer class - all other mailers inherit from this
# Includes BrandedMailer concern for organization white-labeling support
class ApplicationMailer < ActionMailer::Base
  include BrandedMailer

  default from: -> { default_from_address }
  layout "mailer"

  private

  def default_from_address
    # Use custom from address if verified, otherwise platform default
    if @branding&.custom_from_address.present? && @branding&.email_domain_verified?
      @branding.custom_from_address
    else
      PlatformBrand.default_from_email
    end
  end
end
