# frozen_string_literal: true

require "test_helper"

class CompleteI9Section1ServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
    @verification = i9_verifications(:pending_section1)
  end

  teardown do
    Current.reset
  end

  test "completes section 1 with valid params" do
    result = CompleteI9Section1Service.call(
      i9_verification: @verification,
      section1_params: {
        citizenship_status: "citizen",
        attestation_accepted: true
      },
      ip_address: "192.168.1.1",
      user_agent: "Mozilla/5.0"
    )

    assert result.success?
    @verification.reload
    assert_equal "section1_complete", @verification.status
    assert @verification.attestation_accepted?
    assert_equal "citizen", @verification.citizenship_status
    assert_not_nil @verification.section1_completed_at
    assert_equal "192.168.1.1", @verification.section1_signature_ip
  end

  test "updates application i9_status" do
    CompleteI9Section1Service.call(
      i9_verification: @verification,
      section1_params: {
        citizenship_status: "citizen",
        attestation_accepted: true
      },
      ip_address: "192.168.1.1",
      user_agent: "Mozilla/5.0"
    )

    @verification.application.reload
    assert_equal "section1_complete", @verification.application.i9_status
  end

  test "fails without attestation" do
    result = CompleteI9Section1Service.call(
      i9_verification: @verification,
      section1_params: {
        citizenship_status: "citizen",
        attestation_accepted: false
      },
      ip_address: "192.168.1.1",
      user_agent: "Mozilla/5.0"
    )

    assert result.failure?
    assert_equal :attestation_required, result.failure
  end

  test "fails without citizenship status" do
    result = CompleteI9Section1Service.call(
      i9_verification: @verification,
      section1_params: {
        citizenship_status: "",
        attestation_accepted: true
      },
      ip_address: "192.168.1.1",
      user_agent: "Mozilla/5.0"
    )

    assert result.failure?
    assert_equal :citizenship_required, result.failure
  end

  test "fails with invalid citizenship status" do
    result = CompleteI9Section1Service.call(
      i9_verification: @verification,
      section1_params: {
        citizenship_status: "invalid",
        attestation_accepted: true
      },
      ip_address: "192.168.1.1",
      user_agent: "Mozilla/5.0"
    )

    assert result.failure?
    assert_equal :invalid_citizenship_status, result.failure
  end

  test "fails if not in pending_section1 status" do
    verification = i9_verifications(:section1_complete)

    result = CompleteI9Section1Service.call(
      i9_verification: verification,
      section1_params: {
        citizenship_status: "citizen",
        attestation_accepted: true
      },
      ip_address: "192.168.1.1",
      user_agent: "Mozilla/5.0"
    )

    assert result.failure?
    assert_equal :invalid_status, result.failure
  end

  test "requires alien documentation for alien_authorized status" do
    result = CompleteI9Section1Service.call(
      i9_verification: @verification,
      section1_params: {
        citizenship_status: "alien_authorized",
        attestation_accepted: true
        # Missing: alien_number, i94_number, or foreign_passport_number
      },
      ip_address: "192.168.1.1",
      user_agent: "Mozilla/5.0"
    )

    assert result.failure?
    assert_equal :alien_documentation_required, result.failure
  end

  test "accepts alien_authorized with alien_number" do
    result = CompleteI9Section1Service.call(
      i9_verification: @verification,
      section1_params: {
        citizenship_status: "alien_authorized",
        attestation_accepted: true,
        alien_number: "A123456789",
        alien_expiration_date: 1.year.from_now.to_date
      },
      ip_address: "192.168.1.1",
      user_agent: "Mozilla/5.0"
    )

    assert result.success?
    @verification.reload
    assert_equal "alien_authorized", @verification.citizenship_status
  end

  test "queues notification job" do
    assert_enqueued_with(job: I9NotificationJob) do
      CompleteI9Section1Service.call(
        i9_verification: @verification,
        section1_params: {
          citizenship_status: "citizen",
          attestation_accepted: true
        },
        ip_address: "192.168.1.1",
        user_agent: "Mozilla/5.0"
      )
    end
  end
end
