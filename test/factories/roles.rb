# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    organization
    sequence(:name) { |n| "Role #{n}" }
    description { "A custom role" }
    system_role { false }
    permissions { {} }

    trait :admin do
      name { "admin" }
      description { "Full system access" }
      system_role { true }
      permissions do
        {
          "jobs" => %w[create read update delete],
          "candidates" => %w[create read update delete],
          "applications" => %w[create read update delete],
          "users" => %w[create read update delete],
          "settings" => %w[read update]
        }
      end
    end

    trait :recruiter do
      name { "recruiter" }
      description { "Full recruiting access" }
      system_role { true }
      permissions do
        {
          "jobs" => %w[create read update],
          "candidates" => %w[create read update],
          "applications" => %w[create read update delete]
        }
      end
    end

    trait :hiring_manager do
      name { "hiring_manager" }
      description { "Job and candidate management for own jobs" }
      system_role { true }
      permissions do
        {
          "jobs" => %w[read update],
          "candidates" => %w[read],
          "applications" => %w[read update]
        }
      end
    end

    trait :interviewer do
      name { "interviewer" }
      description { "Interview and feedback access" }
      system_role { true }
      permissions do
        {
          "candidates" => %w[read],
          "applications" => %w[read]
        }
      end
    end
  end

  factory :user_role do
    user
    role
    granted_at { Time.current }
    granted_by { nil }
  end
end
