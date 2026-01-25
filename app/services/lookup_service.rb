# frozen_string_literal: true

class LookupService
  class << self
    # Get all values for a lookup type, suitable for select dropdowns
    def values_for_select(type_code, organization: Current.organization, locale: I18n.locale)
      return [] unless organization

      lookup_type = find_type(type_code, organization)
      return [] unless lookup_type

      lookup_type.lookup_values.active.ordered.map do |v|
        [v.name(locale: locale), v.code]
      end
    end

    # Get a single lookup value by type and code
    def find_value(type_code, value_code, organization: Current.organization)
      return nil unless organization

      lookup_type = find_type(type_code, organization)
      return nil unless lookup_type

      lookup_type.lookup_values.find_by(code: value_code)
    end

    # Get the translated name for a lookup value
    def translate(type_code, value_code, organization: Current.organization, locale: I18n.locale)
      value = find_value(type_code, value_code, organization: organization)
      value&.name(locale: locale) || value_code.to_s.humanize
    end

    # Get all active values for a type
    def values(type_code, organization: Current.organization)
      return [] unless organization

      lookup_type = find_type(type_code, organization)
      return [] unless lookup_type

      lookup_type.lookup_values.active.ordered
    end

    # Get valid codes for validation
    def valid_codes(type_code, organization: Current.organization)
      values(type_code, organization: organization).pluck(:code)
    end

    # Get all values with labels for filters/dropdowns (returns array of hashes)
    def all_values(type_code, organization: Current.organization, locale: I18n.locale)
      return [] unless organization

      lookup_type = find_type(type_code, organization)
      return [] unless lookup_type

      lookup_type.lookup_values.active.ordered.map do |v|
        { code: v.code, label: v.name(locale: locale) }
      end
    end

    # Check if a code is valid for a type
    def valid_code?(type_code, value_code, organization: Current.organization)
      valid_codes(type_code, organization: organization).include?(value_code.to_s)
    end

    # Get the default value for a type
    def default_value(type_code, organization: Current.organization)
      return nil unless organization

      lookup_type = find_type(type_code, organization)
      return nil unless lookup_type

      lookup_type.lookup_values.active.find_by(is_default: true) ||
        lookup_type.lookup_values.active.ordered.first
    end

    # Get the default code for a type
    def default_code(type_code, organization: Current.organization)
      default_value(type_code, organization: organization)&.code
    end

    private

    def find_type(type_code, organization)
      LookupType.find_by(organization: organization, code: type_code, active: true)
    end

    # Cache key helper for future caching implementation
    def cache_key(type_code, organization)
      "lookup/#{organization.id}/#{type_code}"
    end
  end
end
