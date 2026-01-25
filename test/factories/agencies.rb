# frozen_string_literal: true

FactoryBot.define do
  factory :agency do
    organization
    sequence(:name) { |n| "Staffing Agency #{n}" }
    contact_email { "contact@agency.example.com" }
    contact_name { "Agency Contact" }
    fee_percentage { 20.0 }
    active { true }
  end
end
