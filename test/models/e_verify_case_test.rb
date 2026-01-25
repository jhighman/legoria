# frozen_string_literal: true

require "test_helper"

class EVerifyCaseTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
    @pending = e_verify_cases(:pending_case)
    @submitted = e_verify_cases(:submitted_case)
    @authorized = e_verify_cases(:authorized_case)
  end

  teardown do
    Current.reset
  end

  # Validations
  test "requires status" do
    everify = EVerifyCase.new(
      organization: @organization,
      i9_verification: i9_verifications(:verified)
    )
    everify.status = nil
    assert_not everify.valid?
    assert_includes everify.errors[:status], "can't be blank"
  end

  test "validates status inclusion" do
    @pending.status = "invalid"
    assert_not @pending.valid?
    assert_includes @pending.errors[:status], "is not included in the list"
  end

  test "case_number must be unique" do
    duplicate = EVerifyCase.new(
      organization: @organization,
      i9_verification: i9_verifications(:section1_complete),
      status: "pending",
      case_number: @submitted.case_number
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:case_number], "has already been taken"
  end

  # State machine
  test "initial status is pending" do
    everify = EVerifyCase.new
    assert_equal "pending", everify.status
  end

  test "can transition from pending to submitted" do
    assert @pending.can_submit?
    # Note: submit! has side effects that require valid i9_verification state
  end

  test "cannot skip to authorized from pending" do
    assert_not @pending.can_authorize?
  end

  # Status helpers
  test "active? returns true for active statuses" do
    assert @pending.active?
    assert @submitted.active?
  end

  test "terminal? returns true for terminal statuses" do
    assert @authorized.terminal?
  end

  test "awaiting_response? returns true for submitted status" do
    assert @submitted.awaiting_response?
  end

  # TNC helpers
  test "calculate_tnc_deadline calculates 8 business days" do
    # Monday calculation
    travel_to Date.new(2026, 1, 26) do # Monday
      deadline = @pending.calculate_tnc_deadline
      expected = Date.new(2026, 2, 5) # 8 business days (skipping weekends)
      assert_equal expected, deadline
    end
  end

  test "tnc_deadline_passed? returns false when no deadline" do
    assert_not @pending.tnc_deadline_passed?
  end

  test "requires_employee_action? returns false when not TNC" do
    assert_not @submitted.requires_employee_action?
  end

  # API response logging
  test "log_response appends to api_responses" do
    initial_count = @pending.api_responses.size
    @pending.log_response({ status: "ok", code: 200 })

    assert_equal initial_count + 1, @pending.api_responses.size
    # The data is stored with string keys when serialized to JSON
    last_response = @pending.api_responses.last
    assert_not_nil last_response
    assert_not_nil last_response["data"] || last_response[:data]
  end

  # Display helpers
  test "status_label returns human readable status" do
    assert_equal "Pending Submission", @pending.status_label
    assert_equal "Awaiting Response", @submitted.status_label
    assert_equal "Employment Authorized", @authorized.status_label
  end

  test "status_color returns appropriate color" do
    assert_equal "gray", @pending.status_color
    assert_equal "blue", @submitted.status_color
    assert_equal "green", @authorized.status_color
  end
end
