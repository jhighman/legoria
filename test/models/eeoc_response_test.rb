# frozen_string_literal: true

require "test_helper"

class EeocResponseTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @response = eeoc_responses(:complete_response)
  end

  def teardown
    Current.organization = nil
  end

  test "valid response" do
    assert @response.valid?
  end

  test "validates gender inclusion" do
    @response.gender = "invalid"
    assert_not @response.valid?
    assert_includes @response.errors[:gender], "is not included in the list"
  end

  test "validates race_ethnicity inclusion" do
    @response.race_ethnicity = "invalid"
    assert_not @response.valid?
    assert_includes @response.errors[:race_ethnicity], "is not included in the list"
  end

  test "validates application uniqueness" do
    duplicate = EeocResponse.new(
      organization: @organization,
      application: @response.application,
      consent_given: true
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:application_id], "has already been taken"
  end

  test "requires consent for data" do
    response = EeocResponse.new(
      organization: @organization,
      application: applications(:rejected_application),
      gender: "male",
      consent_given: false
    )
    assert_not response.valid?
    assert_includes response.errors[:consent_given], "must be provided before collecting EEOC data"
  end

  # Data helpers
  test "any_data_provided? returns true when data present" do
    assert @response.any_data_provided?
  end

  test "all_declined? returns true when all prefer_not_to_say" do
    assert eeoc_responses(:declined_response).all_declined?
  end

  # Display helpers
  test "gender_label returns formatted gender" do
    assert_equal "Female", @response.gender_label
  end

  test "race_ethnicity_label returns formatted race/ethnicity" do
    assert_equal "Asian", @response.race_ethnicity_label
  end

  test "veteran_status_label returns formatted status" do
    assert_equal "Not a Veteran", @response.veteran_status_label
  end

  # Scopes
  test "with_consent scope returns only consented responses" do
    consented = EeocResponse.with_consent
    consented.each { |r| assert r.consent_given? }
  end
end
