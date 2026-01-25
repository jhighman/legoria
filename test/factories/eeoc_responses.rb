# frozen_string_literal: true

FactoryBot.define do
  factory :eeoc_response do
    organization
    application
    consent_given { true }
    consent_timestamp { Time.current }
    collection_context { "application" }

    trait :with_gender do
      gender { "female" }
    end

    trait :with_race do
      race_ethnicity { "asian" }
    end

    trait :with_veteran do
      veteran_status { "not_veteran" }
    end

    trait :with_disability do
      disability_status { "no" }
    end

    trait :complete do
      gender { "female" }
      race_ethnicity { "asian" }
      veteran_status { "not_veteran" }
      disability_status { "no" }
    end

    trait :declined do
      gender { "prefer_not_to_say" }
      race_ethnicity { "prefer_not_to_say" }
      veteran_status { "prefer_not_to_say" }
      disability_status { "prefer_not_to_say" }
    end

    trait :without_consent do
      consent_given { false }
      consent_timestamp { nil }
    end
  end
end
