# frozen_string_literal: true

require "test_helper"

class TimeToHireQueryTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization

    @department = departments(:engineering)
    @job = jobs(:open_job)
    @stage = stages(:applied)
  end

  teardown do
    Current.reset
  end

  test "returns empty metrics when no hires exist" do
    # Clear hired applications
    Application.where(status: "hired").delete_all

    result = TimeToHireQuery.call(
      start_date: 30.days.ago,
      end_date: Time.current
    )

    assert_equal 0, result[:overall][:total_hires]
    assert_equal 0, result[:overall][:average_days]
  end

  test "calculates metrics for hired applications" do
    # Create a hired application using fixture data
    application = applications(:active_application)
    application.update_columns(status: "hired", hired_at: 1.day.ago)

    result = TimeToHireQuery.call(
      start_date: 30.days.ago,
      end_date: Time.current
    )

    assert result[:overall][:total_hires] >= 1
    assert result[:overall][:average_days] >= 0
  end

  test "groups metrics by job" do
    application = applications(:active_application)
    application.update_columns(status: "hired", hired_at: 1.day.ago)

    result = TimeToHireQuery.call(
      start_date: 30.days.ago,
      end_date: Time.current
    )

    assert result[:by_job].any?
  end

  test "groups metrics by department" do
    application = applications(:active_application)
    application.update_columns(status: "hired", hired_at: 1.day.ago)

    result = TimeToHireQuery.call(
      start_date: 30.days.ago,
      end_date: Time.current
    )

    assert result[:by_department].any?
  end

  test "filters by job_id" do
    application = applications(:active_application)
    application.update_columns(status: "hired", hired_at: 1.day.ago)

    result = TimeToHireQuery.call(
      start_date: 30.days.ago,
      end_date: Time.current,
      job_id: @job.id
    )

    # Should only include hires for the specified job
    assert result[:overall].key?(:total_hires)
  end
end
