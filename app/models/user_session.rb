# frozen_string_literal: true

# SA-01: Identity & Access - User session tracking
# Tracks active user sessions for session-based authentication
class UserSession < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  # Scopes
  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  # Class methods
  def self.create_for_user(user, ip_address: nil, user_agent: nil, expires_in: 24.hours)
    token = SecureRandom.urlsafe_base64(32)
    session = create!(
      user: user,
      token_digest: Digest::SHA256.hexdigest(token),
      ip_address: ip_address,
      user_agent: user_agent,
      expires_at: expires_in.from_now,
      last_active_at: Time.current
    )
    [session, token]
  end

  def self.find_by_token(token)
    return nil if token.blank?

    digest = Digest::SHA256.hexdigest(token)
    active.find_by(token_digest: digest)
  end

  def self.cleanup_expired!
    expired.delete_all
  end

  # Instance methods
  def active?
    expires_at > Time.current
  end

  def expired?
    expires_at <= Time.current
  end

  def touch_activity!
    update!(last_active_at: Time.current)
  end

  def extend!(duration = 24.hours)
    update!(expires_at: duration.from_now)
  end

  def invalidate!
    update!(expires_at: Time.current)
  end
end
