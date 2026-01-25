# frozen_string_literal: true

FactoryBot.define do
  factory :stage_transition do
    application
    to_stage factory: :stage
    from_stage { nil }
    moved_by { nil }
    notes { nil }
    duration_hours { nil }

    trait :with_from_stage do
      from_stage factory: :stage
    end

    trait :with_mover do
      moved_by factory: :user
    end

    trait :with_duration do
      duration_hours { rand(1..168) }
    end

    trait :with_notes do
      notes { "Moved by recruiter after phone screen" }
    end
  end
end
