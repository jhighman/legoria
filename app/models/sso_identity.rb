# frozen_string_literal: true

# SA-01: Identity & Access - User's SSO identity link
# Links users to their external SSO identities
class SsoIdentity < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :sso_config

  # Validations
  validates :provider_uid, presence: true
  validates :provider_uid, uniqueness: { scope: :sso_config_id }

  # Scopes
  scope :for_provider, ->(provider) { joins(:sso_config).where(sso_configs: { provider: provider }) }
  scope :recently_used, -> { where("last_used_at > ?", 30.days.ago) }

  # Class methods
  def self.find_by_provider_uid(sso_config:, uid:)
    find_by(sso_config: sso_config, provider_uid: uid)
  end

  def self.link_user(user:, sso_config:, uid:, provider_data: {})
    identity = find_or_initialize_by(user: user, sso_config: sso_config)
    identity.update!(
      provider_uid: uid,
      provider_data: provider_data,
      last_used_at: Time.current
    )
    identity
  end

  # Instance methods
  def record_usage!
    update!(last_used_at: Time.current)
  end

  def stale?
    last_used_at.nil? || last_used_at < 90.days.ago
  end
end
