# frozen_string_literal: true

# SA-01: Identity & Access - SSO configuration
# Supports SAML 2.0 and OIDC authentication
class SsoConfig < ApplicationRecord
  include OrganizationScoped

  # Associations
  has_many :sso_identities, dependent: :destroy
  belongs_to :provisioned_role, class_name: "Role", foreign_key: "default_role_id", optional: true

  # Encryption
  encrypts :client_secret
  encrypts :saml_certificate

  # Providers
  PROVIDERS = %w[saml oidc].freeze

  # Fingerprint algorithms
  FINGERPRINT_ALGORITHMS = %w[sha1 sha256 sha384 sha512].freeze

  # Validations
  validates :provider, presence: true, inclusion: { in: PROVIDERS }

  validates :saml_entity_id, presence: true, if: :saml?
  validates :saml_sso_url, presence: true, if: :saml?
  validates :saml_fingerprint_algorithm, inclusion: { in: FINGERPRINT_ALGORITHMS }, allow_nil: true

  validates :client_id, presence: true, if: :oidc?
  validates :client_secret, presence: true, if: :oidc?

  validate :validate_oidc_endpoints
  validate :validate_allowed_domains

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :saml, -> { where(provider: "saml") }
  scope :oidc, -> { where(provider: "oidc") }

  # Provider checks
  def saml?
    provider == "saml"
  end

  def oidc?
    provider == "oidc"
  end

  # OIDC Discovery
  def discover_oidc_endpoints!
    return false unless oidc? && oidc_discovery_url.present?

    # In production, this would fetch the .well-known/openid-configuration
    # For now, return true to indicate it would work
    true
  end

  def oidc_endpoints_configured?
    return false unless oidc?

    oidc_authorization_endpoint.present? &&
      oidc_token_endpoint.present? &&
      oidc_userinfo_endpoint.present?
  end

  # SAML Configuration
  def saml_settings
    return {} unless saml?

    {
      issuer: saml_entity_id,
      idp_sso_target_url: saml_sso_url,
      idp_slo_target_url: saml_slo_url,
      idp_cert: saml_certificate,
      idp_cert_fingerprint: saml_fingerprint,
      idp_cert_fingerprint_algorithm: "http://www.w3.org/2000/09/xmldsig##{saml_fingerprint_algorithm || 'sha256'}"
    }.compact
  end

  # Attribute mapping
  def map_attributes(raw_attributes)
    return {} if attribute_mapping.blank?

    mapping = attribute_mapping.is_a?(String) ? JSON.parse(attribute_mapping) : attribute_mapping
    mapped = {}
    mapping.each do |local_attr, remote_attr|
      mapped[local_attr.to_sym] = raw_attributes[remote_attr] if raw_attributes.key?(remote_attr)
    end
    mapped
  end

  # Domain restrictions
  def email_domain_allowed?(email)
    return true if allowed_domains.blank?

    domain = email.to_s.split("@").last&.downcase
    return false if domain.blank?

    allowed_domains.any? { |d| d.downcase == domain }
  end

  # Auto-provisioning
  def should_auto_provision?
    auto_provision_users? && enabled?
  end

  def provision_user(attributes)
    return nil unless should_auto_provision?

    email = attributes[:email]
    return nil unless email_domain_allowed?(email)

    user = organization.users.find_or_initialize_by(email: email)
    return user if user.persisted?

    user.assign_attributes(
      first_name: attributes[:first_name] || email.split("@").first,
      last_name: attributes[:last_name] || "",
      password: SecureRandom.hex(32),
      confirmed_at: Time.current
    )

    if user.save
      user.user_roles.create!(role: provisioned_role) if provisioned_role
      user
    end
  end

  # Usage tracking
  def record_login!
    update!(
      last_login_at: Time.current,
      login_count: (login_count || 0) + 1
    )
  end

  # Debug mode helpers
  def log_auth_attempt(success:, details: {})
    return unless debug_mode?

    Rails.logger.info("[SSO Debug] Provider: #{provider}, Success: #{success}, Details: #{details.to_json}")
  end

  private

  def validate_oidc_endpoints
    return unless oidc?
    return if oidc_discovery_url.present?

    if oidc_authorization_endpoint.blank?
      errors.add(:oidc_authorization_endpoint, "is required when discovery URL is not provided")
    end

    if oidc_token_endpoint.blank?
      errors.add(:oidc_token_endpoint, "is required when discovery URL is not provided")
    end
  end

  def validate_allowed_domains
    return if allowed_domains.blank?

    allowed_domains.each do |domain|
      unless domain.match?(/\A[\w.-]+\.\w+\z/)
        errors.add(:allowed_domains, "contains invalid domain: #{domain}")
      end
    end
  end
end
