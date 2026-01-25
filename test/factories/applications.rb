# frozen_string_literal: true

FactoryBot.define do
  factory :application do
    organization
    job
    candidate
    current_stage { association :stage, organization: organization }
    status { "new" }
    source_type { "career_site" }
    applied_at { Time.current }
    last_activity_at { Time.current }
    starred { false }

    trait :hired do
      status { "hired" }
      hired_at { Time.current }
    end

    trait :rejected do
      status { "rejected" }
      rejected_at { Time.current }
      association :rejection_reason
      rejection_notes { "Did not meet minimum qualifications." }
    end

    trait :withdrawn do
      status { "withdrawn" }
      withdrawn_at { Time.current }
    end

    trait :starred do
      starred { true }
    end

    trait :rated do
      rating { 4 }
    end

    trait :from_referral do
      source_type { "referral" }
      source_detail { "Employee Referral Program" }
    end

    trait :from_job_board do
      source_type { "job_board" }
      source_detail { "Indeed" }
    end
  end
end
