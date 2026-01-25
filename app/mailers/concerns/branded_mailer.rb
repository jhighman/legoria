# frozen_string_literal: true

# BrandedMailer concern provides organization branding context to mailers.
# Include this in any mailer that should support white-labeling.
#
# Usage:
#   class MyMailer < ApplicationMailer
#     include BrandedMailer
#
#     def welcome_email(user)
#       set_branding(user.organization)
#       mail(to: user.email, subject: "Welcome!")
#     end
#   end
#
# In views, access branding via @branding instance variable.
#
module BrandedMailer
  extend ActiveSupport::Concern

  included do
    helper_method :brand_primary_color, :brand_name, :brand_footer_text, :show_powered_by?
    before_action :set_default_branding
  end

  private

  def set_branding(organization)
    @organization = organization
    @branding = organization&.branding
  end

  def set_default_branding
    @organization ||= Current.organization
    @branding ||= @organization&.branding
  end

  def brand_primary_color
    @branding&.primary_color.presence || PlatformBrand.primary_color
  end

  def brand_name
    @organization&.name.presence || PlatformBrand.name
  end

  def brand_footer_text
    @branding&.email_footer_text.presence || "Sent via #{PlatformBrand.name}"
  end

  def show_powered_by?
    @branding&.show_powered_by? != false
  end

  def brand_logo_attached?
    @branding&.logo&.attached?
  end

  def brand_logo_url
    return nil unless brand_logo_attached?

    # Use polymorphic_url to generate absolute URL for emails
    Rails.application.routes.url_helpers.rails_blob_url(@branding.logo, host: default_url_options[:host])
  end
end
