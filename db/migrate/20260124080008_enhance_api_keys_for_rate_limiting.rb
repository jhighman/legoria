# frozen_string_literal: true

# Phase 6: Add rate limiting and usage tracking to API keys
class EnhanceApiKeysForRateLimiting < ActiveRecord::Migration[8.0]
  def change
    # Rate limiting
    add_column :api_keys, :rate_limit_per_minute, :integer, default: 60
    add_column :api_keys, :rate_limit_per_hour, :integer, default: 1000
    add_column :api_keys, :rate_limit_per_day, :integer, default: 10000

    # Usage tracking
    add_column :api_keys, :requests_today, :integer, null: false, default: 0
    add_column :api_keys, :requests_this_hour, :integer, null: false, default: 0
    add_column :api_keys, :requests_this_minute, :integer, null: false, default: 0
    add_column :api_keys, :total_requests, :integer, null: false, default: 0

    # Reset timestamps
    add_column :api_keys, :minute_reset_at, :datetime
    add_column :api_keys, :hour_reset_at, :datetime
    add_column :api_keys, :day_reset_at, :datetime

    # API version preference
    add_column :api_keys, :api_version, :string, default: "v1"

    # Description
    add_column :api_keys, :description, :text

    # IP restrictions
    add_column :api_keys, :allowed_ips, :json # Array of allowed IPs/CIDRs
  end
end
