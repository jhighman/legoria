# frozen_string_literal: true

require "test_helper"

class I9VerificationTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
    @verification = i9_verifications(:pending_section1)
  end

  teardown do
    Current.reset
  end

  # Validations
  test "requires organization" do
    Current.organization = nil
    verification = I9Verification.new(
      application: applications(:active_application),
      candidate: candidates(:john_doe),
      status: "pending_section1"
    )
    assert_not verification.valid?
    assert_includes verification.errors[:organization_id], "can't be blank"
  end

  test "requires unique application per organization" do
    duplicate = I9Verification.new(
      organization: @organization,
      application: @verification.application,
      candidate: @verification.candidate,
      status: "pending_section1",
      employee_start_date: 14.days.from_now
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:application_id], "already has an I-9 verification"
  end

  test "validates citizenship status inclusion" do
    @verification.citizenship_status = "invalid"
    assert_not @verification.valid?
    assert_includes @verification.errors[:citizenship_status], "is not included in the list"
  end

  # State machine
  test "initial status is pending_section1" do
    verification = I9Verification.new
    assert_equal "pending_section1", verification.status
  end

  test "can transition from pending_section1 to section1_complete" do
    # Need to set required section 1 fields before transition
    @verification.attestation_accepted = true
    @verification.citizenship_status = "citizen"
    @verification.save!

    assert @verification.can_complete_section1?
    @verification.complete_section1!
    assert_equal "section1_complete", @verification.status
  end

  test "can transition from section1_complete to pending_section2" do
    verification = i9_verifications(:section1_complete)
    assert verification.can_begin_section2?
    verification.begin_section2!
    assert_equal "pending_section2", verification.status
  end

  test "cannot skip to section2 from pending_section1" do
    assert_not @verification.can_begin_section2?
  end

  # Deadline calculations
  test "calculates section2 deadline as 3 business days from start" do
    # Monday start date should have Thursday deadline
    monday = Date.new(2026, 1, 26) # Monday
    @verification.employee_start_date = monday
    @verification.send(:set_deadlines)

    expected_deadline = Date.new(2026, 1, 29) # Thursday (3 business days)
    assert_equal expected_deadline, @verification.deadline_section2
  end

  test "section2_deadline skips weekends" do
    # Friday start date should have Wednesday deadline
    friday = Date.new(2026, 1, 23) # Friday
    @verification.employee_start_date = friday
    @verification.send(:set_deadlines)

    expected_deadline = Date.new(2026, 1, 28) # Wednesday (3 business days, skipping Sat/Sun)
    assert_equal expected_deadline, @verification.deadline_section2
  end

  test "section2_overdue? returns true when past deadline" do
    verification = i9_verifications(:section1_complete)
    verification.update_column(:deadline_section2, Date.yesterday)
    assert verification.section2_overdue?
  end

  test "section2_overdue? returns false when section2 is completed" do
    verification = i9_verifications(:verified)
    verification.update_column(:deadline_section2, Date.yesterday)
    assert_not verification.section2_overdue?
  end

  # Status helpers
  test "active? returns true for active statuses" do
    assert @verification.active?
  end

  test "terminal? returns true for terminal statuses" do
    verification = i9_verifications(:verified)
    assert verification.terminal?
  end

  test "awaiting_section1? returns true for pending_section1" do
    assert @verification.awaiting_section1?
  end

  test "awaiting_section2? returns true for section1_complete" do
    verification = i9_verifications(:section1_complete)
    assert verification.awaiting_section2?
  end

  # Document validation
  test "has_valid_list_a_document? returns true when verified list A exists" do
    verification = i9_verifications(:verified)
    assert verification.has_valid_list_a_document?
  end

  test "documents_valid? accepts list A alone" do
    verification = i9_verifications(:verified)
    assert verification.documents_valid?
  end

  # Display helpers
  test "status_label returns human readable status" do
    assert_equal "Awaiting Employee (Section 1)", @verification.status_label
  end

  test "citizenship_status_label returns human readable citizenship" do
    verification = i9_verifications(:section1_complete)
    assert_equal "U.S. Citizen", verification.citizenship_status_label
  end
end
