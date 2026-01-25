# frozen_string_literal: true

FactoryBot.define do
  factory :stage do
    organization
    sequence(:name) { |n| "Stage #{n}" }
    stage_type { "screening" }
    sequence(:position) { |n| n }
    is_terminal { false }
    is_default { false }
    color { "#3B82F6" }

    trait :applied do
      name { "Applied" }
      stage_type { "applied" }
      is_default { true }
    end

    trait :screening do
      name { "Screening" }
      stage_type { "screening" }
      is_default { true }
    end

    trait :interview do
      name { "Interview" }
      stage_type { "interview" }
      is_default { true }
    end

    trait :offer do
      name { "Offer" }
      stage_type { "offer" }
      is_default { true }
    end

    trait :hired do
      name { "Hired" }
      stage_type { "hired" }
      is_terminal { true }
      is_default { true }
      color { "#10B981" }
    end

    trait :rejected do
      name { "Rejected" }
      stage_type { "rejected" }
      is_terminal { true }
      is_default { true }
      color { "#EF4444" }
    end
  end
end
