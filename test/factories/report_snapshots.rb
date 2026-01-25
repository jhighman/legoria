# frozen_string_literal: true

FactoryBot.define do
  factory :report_snapshot do
    organization
    report_type { "time_to_hire" }
    period_type { "monthly" }
    period_start { 1.month.ago.beginning_of_month.to_date }
    period_end { 1.month.ago.end_of_month.to_date }
    data { { summary: { total: 10, average: 25 } } }
    metadata { { generator_version: "1.0" } }
    generated_at { Time.current }
    generated_by { nil }

    trait :eeoc do
      report_type { "eeoc" }
      data do
        {
          summary: { total_applications: 100, eeoc_responses: 80 },
          by_gender: [],
          by_race_ethnicity: []
        }
      end
    end

    trait :diversity do
      report_type { "diversity" }
      data do
        {
          summary: { diversity_index: 0.7, total_respondents: 50 },
          representation: {}
        }
      end
    end

    trait :pipeline do
      report_type { "pipeline" }
      data do
        {
          funnel: [],
          stage_metrics: []
        }
      end
    end

    trait :weekly do
      period_type { "weekly" }
      period_start { Date.current.beginning_of_week }
      period_end { Date.current.end_of_week }
    end

    trait :daily do
      period_type { "daily" }
      period_start { Date.current }
      period_end { Date.current }
    end

    trait :with_user do
      generated_by factory: :user
    end
  end
end
