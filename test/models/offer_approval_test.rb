# frozen_string_literal: true

require "test_helper"

class OfferApprovalTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @approval = offer_approvals(:pending_approval)
  end

  def teardown
    Current.organization = nil
  end

  test "valid approval" do
    assert @approval.valid?
  end

  test "validates status inclusion" do
    @approval.status = "invalid"
    assert_not @approval.valid?
    assert_includes @approval.errors[:status], "is not included in the list"
  end

  # Status helpers
  test "pending? returns true for pending approvals" do
    assert @approval.pending?
  end

  test "approved? returns true for approved approvals" do
    assert offer_approvals(:approved_approval).approved?
  end

  test "responded? returns true for non-pending approvals" do
    assert offer_approvals(:approved_approval).responded?
    assert_not @approval.responded?
  end

  # Display helpers
  test "status_label returns formatted status" do
    assert_equal "Pending", @approval.status_label
  end

  test "status_color returns appropriate color" do
    assert_equal "yellow", @approval.status_color
    assert_equal "green", offer_approvals(:approved_approval).status_color
  end

  test "waiting_time returns formatted time for pending approvals" do
    @approval.update_column(:requested_at, 2.days.ago)
    assert_match(/\d+d/, @approval.waiting_time)
  end

  # Scopes
  test "pending scope returns only pending approvals" do
    pending = OfferApproval.pending
    pending.each { |a| assert a.pending? }
  end
end
