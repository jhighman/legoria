# frozen_string_literal: true

require "test_helper"

class CreateHiringDecisionServiceTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    # Use new_application which doesn't have a pending decision
    @application = applications(:new_application)
    @user = users(:recruiter)

    # Update application to be in appropriate stage
    @application.update_columns(status: "interviewing")
  end

  def teardown
    Current.organization = nil
  end

  test "creates hiring decision successfully" do
    result = CreateHiringDecisionService.call(
      application: @application,
      decided_by: @user,
      decision: "hire",
      rationale: "Excellent candidate with strong skills.",
      proposed_salary: 100_000,
      proposed_start_date: 2.weeks.from_now.to_date,
      notify_team: false
    )

    assert result.success?
    decision = result.value!
    assert_equal "hire", decision.decision
    assert_equal "pending", decision.status
    assert_equal @user.id, decision.decided_by_id
  end

  test "creates decision without approval required" do
    result = CreateHiringDecisionService.call(
      application: @application,
      decided_by: @user,
      decision: "hire",
      rationale: "Excellent candidate",
      proposed_salary: 100_000,
      proposed_start_date: 2.weeks.from_now.to_date,
      require_approval: false,
      notify_team: false
    )

    assert result.success?
    decision = result.value!
    assert_equal "approved", decision.status
    assert_equal @user.id, decision.approved_by_id
  end

  test "fails if application is nil" do
    result = CreateHiringDecisionService.call(
      application: nil,
      decided_by: @user,
      decision: "hire",
      rationale: "Test",
      notify_team: false
    )

    assert result.failure?
    assert_equal :application_not_found, result.failure
  end

  test "fails if application is not active" do
    @application.update_columns(status: "rejected")

    result = CreateHiringDecisionService.call(
      application: @application,
      decided_by: @user,
      decision: "hire",
      rationale: "Test",
      notify_team: false
    )

    assert result.failure?
    assert_equal :application_not_active, result.failure
  end

  test "fails if application cannot receive decision" do
    @application.update_columns(status: "new")

    result = CreateHiringDecisionService.call(
      application: @application,
      decided_by: @user,
      decision: "hire",
      rationale: "Test",
      notify_team: false
    )

    assert result.failure?
    assert_equal :application_not_ready_for_decision, result.failure
  end

  test "fails if decided_by is nil" do
    result = CreateHiringDecisionService.call(
      application: @application,
      decided_by: nil,
      decision: "hire",
      rationale: "Test",
      notify_team: false
    )

    assert result.failure?
    assert_equal :user_not_found, result.failure
  end

  test "fails if pending decision already exists" do
    # Create a pending decision first
    HiringDecision.create!(
      organization: @organization,
      application: @application,
      decided_by: users(:hiring_manager),
      decision: "hold",
      rationale: "Waiting for more info",
      status: "pending",
      decided_at: Time.current
    )

    result = CreateHiringDecisionService.call(
      application: @application,
      decided_by: @user,
      decision: "hire",
      rationale: "New decision",
      notify_team: false
    )

    assert result.failure?
    assert_equal :pending_decision_exists, result.failure
  end

  test "creates reject decision" do
    result = CreateHiringDecisionService.call(
      application: @application,
      decided_by: @user,
      decision: "reject",
      rationale: "Does not meet requirements.",
      notify_team: false
    )

    assert result.success?
    decision = result.value!
    assert_equal "reject", decision.decision
  end

  test "creates hold decision" do
    result = CreateHiringDecisionService.call(
      application: @application,
      decided_by: @user,
      decision: "hold",
      rationale: "Need more information before deciding.",
      notify_team: false
    )

    assert result.success?
    decision = result.value!
    assert_equal "hold", decision.decision
  end
end
