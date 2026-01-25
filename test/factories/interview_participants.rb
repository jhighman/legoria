# frozen_string_literal: true

FactoryBot.define do
  factory :interview_participant do
    interview
    user { association :user, organization: interview.organization }
    role { "interviewer" }
    status { "pending" }
    feedback_submitted { false }

    trait :lead do
      role { "lead" }
    end

    trait :shadow do
      role { "shadow" }
    end

    trait :note_taker do
      role { "note_taker" }
    end

    trait :accepted do
      status { "accepted" }
      responded_at { 1.day.ago }
    end

    trait :declined do
      status { "declined" }
      responded_at { 1.day.ago }
    end

    trait :tentative do
      status { "tentative" }
      responded_at { 1.day.ago }
    end

    trait :with_feedback do
      feedback_submitted { true }
      feedback_submitted_at { 1.day.ago }
    end
  end
end
