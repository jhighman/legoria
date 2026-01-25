# frozen_string_literal: true

FactoryBot.define do
  factory :candidate do
    organization
    first_name { "Jane" }
    last_name { "Doe" }
    sequence(:email) { |n| "candidate#{n}@example.com" }
    phone { "555-123-4567" }
    location { "New York, NY" }
    parsed_profile { {} }

    trait :with_linkedin do
      linkedin_url { "https://linkedin.com/in/janedoe" }
    end

    trait :with_portfolio do
      portfolio_url { "https://janedoe.com" }
    end

    trait :with_summary do
      summary { "Experienced software engineer with 5+ years in full-stack development." }
    end

    trait :referred do
      association :referred_by, factory: :user
    end

    trait :from_agency do
      association :agency
    end
  end
end
