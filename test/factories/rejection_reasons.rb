# frozen_string_literal: true

FactoryBot.define do
  factory :rejection_reason do
    organization
    sequence(:name) { |n| "Rejection Reason #{n}" }
    category { "not_qualified" }
    requires_notes { false }
    active { true }
    position { 0 }

    trait :not_qualified do
      name { "Does not meet minimum qualifications" }
      category { "not_qualified" }
    end

    trait :timing do
      name { "Position filled" }
      category { "timing" }
    end

    trait :compensation do
      name { "Salary expectations too high" }
      category { "compensation" }
    end

    trait :culture_fit do
      name { "Not a culture fit" }
      category { "culture_fit" }
      requires_notes { true }
    end

    trait :withdrew do
      name { "Candidate withdrew" }
      category { "withdrew" }
    end
  end
end
