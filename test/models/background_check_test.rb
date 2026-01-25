# frozen_string_literal: true

require "test_helper"

class BackgroundCheckTest < ActiveSupport::TestCase
  def setup
    @check = background_checks(:pending_check)
  end

  # Validations
  test "valid background check" do
    assert @check.valid?
  end

  test "validates status inclusion" do
    @check.status = "invalid"
    assert_not @check.valid?
    assert_includes @check.errors[:status], "is not included in the list"
  end

  test "validates result inclusion" do
    @check.result = "invalid"
    assert_not @check.valid?
    assert_includes @check.errors[:result], "is not included in the list"
  end

  test "validates check_types" do
    @check.check_types = ["invalid_type"]
    assert_not @check.valid?
    assert_includes @check.errors[:check_types], "contains invalid types: invalid_type"
  end

  # Associations
  test "belongs to organization" do
    assert_respond_to @check, :organization
    assert_equal organizations(:acme), @check.organization
  end

  test "belongs to application" do
    assert_respond_to @check, :application
  end

  test "belongs to candidate" do
    assert_respond_to @check, :candidate
  end

  test "belongs to integration" do
    assert_respond_to @check, :integration
    assert_equal integrations(:checkr_integration), @check.integration
  end

  # Status methods
  test "pending? returns true for pending status" do
    assert @check.pending?
  end

  test "consent_required? returns true for consent_required status" do
    check = background_checks(:consent_required_check)
    assert check.consent_required?
  end

  test "in_progress? returns true for in_progress status" do
    check = background_checks(:in_progress_check)
    assert check.in_progress?
  end

  test "completed? returns true for completed status" do
    @check.status = "completed"
    assert @check.completed?
  end

  # Result methods
  test "clear? returns true for clear result" do
    @check.result = "clear"
    assert @check.clear?
  end

  test "adverse? returns true for adverse result" do
    @check.result = "adverse"
    assert @check.adverse?
  end

  test "needs_review? returns true for consider or adverse results" do
    @check.result = "consider"
    assert @check.needs_review?

    @check.result = "adverse"
    assert @check.needs_review?

    @check.result = "clear"
    assert_not @check.needs_review?
  end

  # Workflow methods
  test "request_consent! transitions to consent_required" do
    @check.request_consent!

    assert @check.consent_required?
    assert_not_nil @check.consent_requested_at
    assert_equal "email", @check.consent_method
  end

  test "record_consent! transitions from consent_required" do
    check = background_checks(:consent_required_check)
    check.record_consent!

    assert check.consent_given?
    assert_not_nil check.consent_given_at
  end

  test "submit! transitions from consent_given" do
    @check.update!(status: "consent_given")
    @check.submit!

    assert @check.in_progress?
    assert_not_nil @check.submitted_at
    assert_not_nil @check.started_at
  end

  test "complete! with clear result completes check" do
    check = background_checks(:in_progress_check)
    check.complete!(result: "clear", result_summary: "All clear")

    assert check.completed?
    assert_equal "clear", check.result
    assert_not_nil check.completed_at
  end

  test "complete! with adverse result sets review_required" do
    check = background_checks(:in_progress_check)
    check.complete!(result: "adverse", result_summary: "Issues found")

    assert check.review_required?
    assert_equal "adverse", check.result
  end

  test "finalize_review! completes after review" do
    @check.update!(status: "review_required", result: "consider")
    @check.finalize_review!(final_result: "clear")

    assert @check.completed?
    assert_equal "clear", @check.result
    assert_not_nil @check.completed_at
  end

  test "cancel! marks check as cancelled" do
    @check.cancel!(reason: "Candidate withdrew")

    assert @check.cancelled?
    assert_equal "Candidate withdrew", @check.result_summary
  end

  test "cancel! fails for completed checks" do
    @check.update!(status: "completed")
    result = @check.cancel!

    assert_not result
    assert @check.completed? # Status unchanged
  end

  test "update_from_provider! updates fields" do
    check = background_checks(:in_progress_check)
    check.update_from_provider!(
      external_id: "new_id",
      result: "clear",
      result_summary: "All checks passed",
      status: "completed"
    )

    assert_equal "new_id", check.external_id
    assert_equal "clear", check.result
    assert_equal "All checks passed", check.result_summary
    assert check.completed?
  end

  # Scopes
  test "pending scope returns pending checks" do
    pending = BackgroundCheck.pending
    assert pending.include?(@check)
  end

  test "with_adverse_results scope returns consider and adverse" do
    @check.update!(result: "consider")
    adverse = BackgroundCheck.with_adverse_results
    assert adverse.include?(@check)
  end
end
