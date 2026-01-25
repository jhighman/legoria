# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    organization
    sequence(:email) { |n| "user#{n}@example.com" }
    first_name { "Test" }
    last_name { "User" }
    password { "password123" }
    password_confirmation { "password123" }
    active { true }
    confirmed_at { Time.current }

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :locked do
      locked_at { Time.current }
      failed_attempts { 5 }
    end

    trait :admin do
      after(:create) do |user|
        role = Role.find_or_create_by!(organization: user.organization, name: "admin") do |r|
          r.description = "Full system access"
          r.system_role = true
          r.permissions = { "users" => %w[create read update delete] }
        end
        UserRole.find_or_create_by!(user: user, role: role) { |ur| ur.granted_at = Time.current }
      end
    end

    trait :recruiter do
      after(:create) do |user|
        role = Role.find_or_create_by!(organization: user.organization, name: "recruiter") do |r|
          r.description = "Full recruiting access"
          r.system_role = true
          r.permissions = { "jobs" => %w[create read update] }
        end
        UserRole.find_or_create_by!(user: user, role: role) { |ur| ur.granted_at = Time.current }
      end
    end

    trait :hiring_manager do
      after(:create) do |user|
        role = Role.find_or_create_by!(organization: user.organization, name: "hiring_manager") do |r|
          r.description = "Job and candidate management"
          r.system_role = true
          r.permissions = { "jobs" => %w[read update] }
        end
        UserRole.find_or_create_by!(user: user, role: role) { |ur| ur.granted_at = Time.current }
      end
    end

    trait :interviewer do
      after(:create) do |user|
        role = Role.find_or_create_by!(organization: user.organization, name: "interviewer") do |r|
          r.description = "Interview and feedback access"
          r.system_role = true
          r.permissions = { "candidates" => %w[read] }
        end
        UserRole.find_or_create_by!(user: user, role: role) { |ur| ur.granted_at = Time.current }
      end
    end
  end
end
