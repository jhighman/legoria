# frozen_string_literal: true

require "test_helper"

class HiringDecisionTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @pending = hiring_decisions(:pending_hire_decision)
    @approved = hiring_decisions(:approved_hire_decision)
  end

  def teardown
    Current.organization = nil
  end

  test "valid hiring decision" do
    assert @pending.valid?
  end

  test "requires decision" do
    @pending.decision = nil
    assert_not @pending.valid?
    assert_includes @pending.errors[:decision], "can't be blank"
  end

  test "validates decision inclusion" do
    new_decision = HiringDecision.new(
      organization: @organization,
      application: applications(:active_application),
      decided_by: users(:recruiter),
      decision: "invalid",
      rationale: "Test",
      decided_at: Time.current
    )
    assert_not new_decision.valid?
    assert_includes new_decision.errors[:decision], "is not included in the list"
  end

  test "requires rationale" do
    @pending.rationale = nil
    assert_not @pending.valid?
    assert_includes @pending.errors[:rationale], "can't be blank"
  end

  # Decision helpers
  test "hire? returns true for hire decisions" do
    assert @pending.hire?
    assert_not hiring_decisions(:rejected_hold_decision).hire?
  end

  test "hold? returns true for hold decisions" do
    assert hiring_decisions(:rejected_hold_decision).hold?
    assert_not @pending.hold?
  end

  # Status helpers
  test "pending? returns true for pending decisions" do
    assert @pending.pending?
    assert_not @approved.pending?
  end

  test "approved? returns true for approved decisions" do
    assert @approved.approved?
    assert_not @pending.approved?
  end

  # Immutability
  test "cannot update hiring decision" do
    assert_raises ActiveRecord::ReadOnlyRecord do
      @pending.update!(rationale: "Changed")
    end
  end

  test "cannot destroy hiring decision" do
    assert_raises ActiveRecord::ReadOnlyRecord do
      @pending.destroy!
    end
  end

  # Approval workflow
  test "can_approve? returns true for pending decisions" do
    assert @pending.can_approve?
    assert_not @approved.can_approve?
  end

  test "approve! changes status to approved" do
    approver = users(:hiring_manager)

    # Put application in offered state so it can transition to hired
    @pending.application.update_columns(status: "offered")

    @pending.approve!(approved_by: approver)

    assert @pending.approved?
    assert_equal approver.id, @pending.approved_by_id
    assert_not_nil @pending.approved_at
  end

  test "reject_approval! changes status to rejected" do
    @pending.reject_approval!(rejected_by: users(:hiring_manager), reason: "Need more info")

    assert @pending.status == "rejected"
    assert_not_nil @pending.rejected_at
  end

  # Salary formatting
  test "proposed_salary_formatted returns formatted currency" do
    @pending.proposed_salary = 95000
    @pending.proposed_salary_currency = "USD"
    assert_equal "$95,000", @pending.proposed_salary_formatted
  end

  # One pending per application
  test "prevents multiple pending decisions for same application" do
    new_decision = HiringDecision.new(
      organization: @organization,
      application: @pending.application,
      decided_by: users(:hiring_manager),
      decision: "reject",
      rationale: "Another decision",
      status: "pending"
    )

    assert_not new_decision.valid?
    assert_includes new_decision.errors[:application], "already has a pending hiring decision"
  end

  # Scopes
  test "pending scope returns only pending decisions" do
    pending = HiringDecision.pending
    pending.each { |d| assert d.pending? }
  end

  test "approved scope returns only approved decisions" do
    approved = HiringDecision.approved
    approved.each { |d| assert d.approved? }
  end

  test "hires scope returns only hire decisions" do
    hires = HiringDecision.hires
    hires.each { |d| assert d.hire? }
  end
end
