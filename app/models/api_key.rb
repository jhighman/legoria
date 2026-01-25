# frozen_string_literal: true

# SA-01/SA-11: Identity & Access / Integration - API key management
# Provides programmatic access to the API with rate limiting
class ApiKey < ApplicationRecord
  include OrganizationScoped

  # Associations
  belongs_to :user

  # Encryption - use deterministic for key_digest so find_by works
  encrypts :key_digest, deterministic: true

  # Validations
  validates :name, presence: true
  validates :key_prefix, presence: true
  validates :key_digest, presence: true, uniqueness: true
  validates :api_version, inclusion: { in: %w[v1 v2] }, allow_nil: true

  validate :validate_allowed_ips

  # Scopes
  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }

  # Class methods
  def self.generate(user:, name:, scopes: [], expires_at: nil)
    key = SecureRandom.hex(32)
    prefix = key[0..7]

    api_key = new(
      user: user,
      organization: user.organization,
      name: name,
      key_prefix: prefix,
      key_digest: Digest::SHA256.hexdigest(key),
      scopes: scopes,
      expires_at: expires_at
    )

    if api_key.save
      [api_key, key] # Return both the record and the plaintext key
    else
      [api_key, nil]
    end
  end

  def self.authenticate(key)
    return nil if key.blank?

    digest = Digest::SHA256.hexdigest(key)
    find_by(key_digest: digest)&.tap do |api_key|
      return nil unless api_key.active?

      api_key.record_usage!
    end
  end

  # Instance methods
  def active?
    revoked_at.nil? && !expired?
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def record_usage!
    update!(last_used_at: Time.current)
    increment_request_counters!
  end

  # Rate limiting
  def rate_limited?
    check_rate_limits!
  end

  def rate_limit_status
    reset_expired_counters!
    {
      minute: { used: requests_this_minute, limit: rate_limit_per_minute, resets_at: minute_reset_at },
      hour: { used: requests_this_hour, limit: rate_limit_per_hour, resets_at: hour_reset_at },
      day: { used: requests_today, limit: rate_limit_per_day, resets_at: day_reset_at }
    }
  end

  def has_scope?(scope)
    scopes&.include?(scope.to_s)
  end

  def ip_allowed?(ip)
    return true if allowed_ips.blank?

    allowed_ips.any? do |allowed|
      if allowed.include?("/")
        # CIDR notation
        IPAddr.new(allowed).include?(ip)
      else
        allowed == ip
      end
    end
  rescue IPAddr::InvalidAddressError
    false
  end

  private

  def increment_request_counters!
    reset_expired_counters!

    now = Time.current
    self.minute_reset_at ||= 1.minute.from_now
    self.hour_reset_at ||= 1.hour.from_now
    self.day_reset_at ||= 1.day.from_now

    increment!(:requests_this_minute)
    increment!(:requests_this_hour)
    increment!(:requests_today)
    increment!(:total_requests)
  end

  def reset_expired_counters!
    now = Time.current

    if minute_reset_at.present? && minute_reset_at <= now
      self.requests_this_minute = 0
      self.minute_reset_at = 1.minute.from_now
    end

    if hour_reset_at.present? && hour_reset_at <= now
      self.requests_this_hour = 0
      self.hour_reset_at = 1.hour.from_now
    end

    if day_reset_at.present? && day_reset_at <= now
      self.requests_today = 0
      self.day_reset_at = 1.day.from_now
    end

    save! if changed?
  end

  def check_rate_limits!
    reset_expired_counters!

    return :minute_limit if rate_limit_per_minute.present? && requests_this_minute >= rate_limit_per_minute
    return :hour_limit if rate_limit_per_hour.present? && requests_this_hour >= rate_limit_per_hour
    return :day_limit if rate_limit_per_day.present? && requests_today >= rate_limit_per_day

    nil
  end

  def validate_allowed_ips
    return if allowed_ips.blank?

    allowed_ips.each do |ip|
      IPAddr.new(ip)
    rescue IPAddr::InvalidAddressError
      errors.add(:allowed_ips, "contains invalid IP address: #{ip}")
    end
  end
end
