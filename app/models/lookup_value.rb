# frozen_string_literal: true

class LookupValue < ApplicationRecord
  # Override translations reader to handle string vs hash (SQLite/fixtures issue)
  def translations
    value = super
    return value if value.is_a?(Hash)

    value.is_a?(String) ? JSON.parse(value) : {}
  rescue JSON::ParserError
    {}
  end

  # Override metadata reader similarly
  def metadata
    value = super
    return value if value.is_a?(Hash)

    value.is_a?(String) ? JSON.parse(value) : {}
  rescue JSON::ParserError
    {}
  end

  # Associations
  belongs_to :lookup_type

  # Validations
  validates :code, presence: true,
                   uniqueness: { scope: :lookup_type_id, case_sensitive: false },
                   format: { with: /\A[a-z][a-z0-9_]*\z/, message: "must be lowercase with underscores" }
  validates :translations, presence: true
  validate :validate_default_translation

  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :code) }
  scope :default_first, -> { order(is_default: :desc, position: :asc) }

  # Callbacks
  before_save :ensure_single_default

  # Delegate organization access
  delegate :organization, to: :lookup_type

  # Translation helpers
  def name(locale: I18n.locale)
    translation_for(locale, "name") || code.humanize
  end

  def description(locale: I18n.locale)
    translation_for(locale, "description")
  end

  def translation_for(locale, field)
    locale_str = locale.to_s

    # Try exact locale
    if translations[locale_str] && translations[locale_str][field].present?
      return translations[locale_str][field]
    end

    # Try organization default locale
    org_locale = lookup_type.organization.default_locale
    if org_locale != locale_str && translations[org_locale] && translations[org_locale][field].present?
      return translations[org_locale][field]
    end

    # Fallback to English
    if locale_str != "en" && org_locale != "en" && translations["en"] && translations["en"][field].present?
      return translations["en"][field]
    end

    nil
  end

  def set_translation(locale, name:, description: nil)
    self.translations = translations.merge(
      locale.to_s => {
        "name" => name,
        "description" => description
      }.compact
    )
  end

  def available_locales
    translations.keys
  end

  # Metadata helpers
  def icon
    metadata&.dig("icon")
  end

  def color
    metadata&.dig("color")
  end

  private

  def validate_default_translation
    # Must have at least English or org default locale translation
    return if translations.blank?

    org_locale = lookup_type&.organization&.default_locale || "en"
    has_valid_translation = translations["en"].present? || translations[org_locale].present?

    unless has_valid_translation
      errors.add(:translations, "must include English or organization default locale")
    end
  end

  def ensure_single_default
    return unless is_default? && is_default_changed?

    # Unset other defaults for this lookup type
    LookupValue.where(lookup_type_id: lookup_type_id, is_default: true)
               .where.not(id: id)
               .update_all(is_default: false)
  end
end
