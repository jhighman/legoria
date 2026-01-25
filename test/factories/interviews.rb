# frozen_string_literal: true

FactoryBot.define do
  factory :interview do
    organization
    application
    job { application.job }
    scheduled_by factory: :user
    interview_type { "video" }
    status { "scheduled" }
    title { "Interview - #{application.candidate.full_name}" }
    scheduled_at { 3.days.from_now }
    duration_minutes { 60 }
    timezone { "UTC" }

    trait :confirmed do
      status { "confirmed" }
      confirmed_at { 1.day.ago }
    end

    trait :completed do
      status { "completed" }
      scheduled_at { 2.days.ago }
      completed_at { 2.days.ago }
    end

    trait :cancelled do
      status { "cancelled" }
      scheduled_at { 1.day.ago }
      cancelled_at { 2.days.ago }
      cancellation_reason { "Position filled" }
    end

    trait :no_show do
      status { "no_show" }
      scheduled_at { 1.day.ago }
    end

    trait :phone_screen do
      interview_type { "phone_screen" }
      duration_minutes { 30 }
    end

    trait :onsite do
      interview_type { "onsite" }
      duration_minutes { 90 }
      location { "123 Main St, Suite 100" }
    end

    trait :technical do
      interview_type { "technical" }
      duration_minutes { 90 }
    end

    trait :with_video_link do
      video_meeting_url { "https://meet.example.com/interview123" }
    end

    trait :with_participants do
      after(:create) do |interview|
        create(:interview_participant, :lead, interview: interview)
        create(:interview_participant, interview: interview)
      end
    end
  end
end
