# frozen_string_literal: true

FactoryBot.define do
  factory :department do
    organization
    sequence(:name) { |n| "Department #{n}" }
    sequence(:code) { |n| "DEPT#{n}" }
    position { 0 }

    trait :engineering do
      name { "Engineering" }
      code { "ENG" }
    end

    trait :product do
      name { "Product" }
      code { "PROD" }
    end

    trait :sales do
      name { "Sales" }
      code { "SALES" }
    end

    trait :hr do
      name { "Human Resources" }
      code { "HR" }
    end
  end
end
