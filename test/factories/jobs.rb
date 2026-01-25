# frozen_string_literal: true

FactoryBot.define do
  factory :job do
    organization
    sequence(:title) { |n| "Software Engineer #{n}" }
    description { "We are looking for a talented engineer to join our team." }
    requirements { "5+ years of experience required." }
    location { "San Francisco, CA" }
    location_type { "hybrid" }
    employment_type { "full_time" }
    status { "draft" }
    headcount { 1 }
    filled_count { 0 }

    trait :with_salary do
      salary_min { 100_000_00 } # cents
      salary_max { 150_000_00 }
      salary_currency { "USD" }
      salary_visible { false }
    end

    trait :open do
      status { "open" }
      opened_at { Time.current }
    end

    trait :pending_approval do
      status { "pending_approval" }
    end

    trait :closed do
      status { "closed" }
      opened_at { 30.days.ago }
      closed_at { Time.current }
      close_reason { "filled" }
    end

    trait :with_hiring_manager do
      association :hiring_manager, factory: [:user, :hiring_manager]
    end

    trait :with_recruiter do
      association :recruiter, factory: [:user, :recruiter]
    end
  end
end
