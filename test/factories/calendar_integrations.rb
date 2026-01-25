# frozen_string_literal: true

FactoryBot.define do
  factory :calendar_integration do
    user
    provider { "google" }
    calendar_id { "primary" }
    access_token_encrypted { "encrypted_token_123" }
    refresh_token_encrypted { "encrypted_refresh_456" }
    token_expires_at { 1.hour.from_now }
    active { true }

    trait :google do
      provider { "google" }
    end

    trait :outlook do
      provider { "outlook" }
    end

    trait :apple do
      provider { "apple" }
    end

    trait :expired do
      token_expires_at { 1.hour.ago }
    end

    trait :inactive do
      active { false }
    end

    trait :with_sync_error do
      sync_error { "Failed to connect to calendar API" }
    end

    trait :recently_synced do
      last_synced_at { 5.minutes.ago }
    end
  end
end
