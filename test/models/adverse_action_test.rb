# frozen_string_literal: true

require "test_helper"

class AdverseActionTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @adverse_action = adverse_actions(:draft_adverse_action)
  end

  def teardown
    Current.organization = nil
  end

  test "valid adverse action" do
    assert @adverse_action.valid?
  end

  test "requires action_type" do
    @adverse_action.action_type = nil
    assert_not @adverse_action.valid?
    assert_includes @adverse_action.errors[:action_type], "can't be blank"
  end

  test "validates action_type inclusion" do
    @adverse_action.action_type = "invalid"
    assert_not @adverse_action.valid?
    assert_includes @adverse_action.errors[:action_type], "is not included in the list"
  end

  test "requires reason_category" do
    @adverse_action.reason_category = nil
    assert_not @adverse_action.valid?
    assert_includes @adverse_action.errors[:reason_category], "can't be blank"
  end

  test "validates reason_category inclusion" do
    @adverse_action.reason_category = "invalid"
    assert_not @adverse_action.valid?
    assert_includes @adverse_action.errors[:reason_category], "is not included in the list"
  end

  # Status helpers
  test "draft? returns true for draft actions" do
    assert @adverse_action.draft?
  end

  test "waiting_period? returns true for waiting actions" do
    assert adverse_actions(:pre_adverse_sent).waiting_period?
  end

  test "completed? returns true for completed actions" do
    assert adverse_actions(:completed_adverse_action).completed?
  end

  # Workflow helpers
  test "can_send_pre_adverse? returns true for draft" do
    assert @adverse_action.can_send_pre_adverse?
  end

  test "can_send_final? returns false during waiting period" do
    waiting = adverse_actions(:pre_adverse_sent)
    assert_not waiting.can_send_final?
  end

  # Dispute tracking
  test "record_dispute! sets dispute fields" do
    waiting = adverse_actions(:pre_adverse_sent)
    waiting.record_dispute!("I dispute this finding")

    assert waiting.candidate_disputed?
    assert_equal "I dispute this finding", waiting.dispute_details
    assert waiting.dispute_received_at.present?
  end

  # Display helpers
  test "status_label returns formatted status" do
    assert_equal "Draft", @adverse_action.status_label
    assert_equal "Waiting Period", adverse_actions(:pre_adverse_sent).status_label
  end

  test "status_color returns appropriate color" do
    assert_equal "gray", @adverse_action.status_color
    assert_equal "orange", adverse_actions(:pre_adverse_sent).status_color
  end

  test "action_type_label returns formatted type" do
    assert_equal "Rejection", @adverse_action.action_type_label
  end

  test "days_remaining_in_waiting returns count" do
    waiting = adverse_actions(:pre_adverse_sent)
    remaining = waiting.days_remaining_in_waiting
    assert remaining >= 0
  end

  # Scopes
  test "drafts scope returns only draft actions" do
    drafts = AdverseAction.drafts
    drafts.each { |a| assert a.draft? }
  end

  test "active scope returns non-terminal actions" do
    active = AdverseAction.active
    active.each { |a| assert_not a.completed? && !a.cancelled? }
  end

  test "with_disputes scope returns disputed actions" do
    disputed = AdverseAction.with_disputes
    disputed.each { |a| assert a.candidate_disputed? }
  end
end
