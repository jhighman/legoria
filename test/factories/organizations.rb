# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization #{n}" }
    sequence(:subdomain) { |n| "org#{n}" }
    timezone { "America/New_York" }
    default_currency { "USD" }
    default_locale { "en" }
    settings { {} }
    plan { "trial" }

    trait :with_billing do
      billing_email { "billing@example.com" }
    end

    trait :paid do
      plan { "professional" }
    end
  end
end
