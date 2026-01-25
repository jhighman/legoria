# frozen_string_literal: true

class OrganizationBranding < ApplicationRecord
  # Associations
  belongs_to :organization

  # Logo attachment
  has_one_attached :logo
  has_one_attached :favicon
  has_one_attached :cover_image

  # Validations
  validates :primary_color, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a valid hex color" }, allow_blank: true
  validates :secondary_color, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a valid hex color" }, allow_blank: true
  validates :accent_color, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a valid hex color" }, allow_blank: true
  validates :text_color, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a valid hex color" }, allow_blank: true
  validates :background_color, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a valid hex color" }, allow_blank: true

  validates :linkedin_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validates :twitter_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validates :facebook_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validates :instagram_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validates :glassdoor_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

  validates :meta_title, length: { maximum: 70 }
  validates :meta_description, length: { maximum: 160 }

  validate :valid_custom_css

  # CSS variable generation
  def css_variables
    {
      "--brand-primary" => primary_color,
      "--brand-secondary" => secondary_color,
      "--brand-accent" => accent_color,
      "--brand-text" => text_color,
      "--brand-background" => background_color,
      "--brand-font-family" => font_family,
      "--brand-heading-font" => heading_font_family || font_family
    }.compact
  end

  def css_variables_style
    css_variables.map { |k, v| "#{k}: #{v};" }.join(" ")
  end

  # SEO helpers
  def page_title(page_name = nil)
    if page_name.present?
      "#{page_name} | #{meta_title.presence || organization.name}"
    else
      meta_title.presence || "Careers at #{organization.name}"
    end
  end

  def page_description
    meta_description.presence || "Explore career opportunities at #{organization.name}. #{company_tagline}"
  end

  # Social links
  def social_links
    {
      linkedin: linkedin_url,
      twitter: twitter_url,
      facebook: facebook_url,
      instagram: instagram_url,
      glassdoor: glassdoor_url
    }.compact_blank
  end

  def has_social_links?
    social_links.present?
  end

  # Filter settings
  def enabled_filters
    filters = []
    filters << :department if show_department_filter?
    filters << :location if show_location_filter?
    filters << :employment_type if show_employment_type_filter?
    filters
  end

  private

  def valid_custom_css
    return if custom_css.blank?

    # Basic CSS validation - check for potential XSS
    dangerous_patterns = [
      /javascript:/i,
      /expression\s*\(/i,
      /url\s*\(\s*["']?\s*data:/i,
      /@import/i
    ]

    dangerous_patterns.each do |pattern|
      if custom_css.match?(pattern)
        errors.add(:custom_css, "contains potentially unsafe content")
        return
      end
    end
  end
end
