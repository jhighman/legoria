# frozen_string_literal: true

require "test_helper"

class OfferTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @offer = offers(:draft_offer)
  end

  def teardown
    Current.organization = nil
  end

  test "valid offer" do
    assert @offer.valid?
  end

  test "requires title" do
    @offer.title = nil
    assert_not @offer.valid?
    assert_includes @offer.errors[:title], "can't be blank"
  end

  test "validates status inclusion" do
    @offer.status = "invalid"
    assert_not @offer.valid?
    assert_includes @offer.errors[:status], "is not included in the list"
  end

  test "validates salary is positive" do
    @offer.salary = -1000
    assert_not @offer.valid?
    assert @offer.errors[:salary].any?
  end

  # Status helpers
  test "draft? returns true for draft offers" do
    assert @offer.draft?
  end

  test "pending_approval? returns true for pending offers" do
    assert offers(:pending_approval_offer).pending_approval?
  end

  test "sent? returns true for sent offers" do
    assert offers(:sent_offer).sent?
  end

  test "accepted? returns true for accepted offers" do
    assert offers(:accepted_offer).accepted?
  end

  # Workflow helpers
  test "can_edit? returns true for draft offers" do
    assert @offer.can_edit?
  end

  test "can_edit? returns false for sent offers" do
    assert_not offers(:sent_offer).can_edit?
  end

  # Workflow actions
  test "submit_for_approval! changes status to pending_approval" do
    @offer.submit_for_approval!
    assert @offer.pending_approval?
  end

  test "submit_for_approval! fails if not draft" do
    sent = offers(:sent_offer)
    assert_raises(StandardError) { sent.submit_for_approval! }
  end

  # Compensation helpers
  test "total_first_year_compensation includes salary and bonuses" do
    total = @offer.total_first_year_compensation
    assert_equal 148000, total # 120000 + 10000 + (120000 * 0.15)
  end

  test "compensation_summary returns formatted string" do
    summary = @offer.compensation_summary
    assert_includes summary, "$120,000"
    assert_includes summary, "signing bonus"
    assert_includes summary, "15.0%"
  end

  # Display helpers
  test "status_label returns formatted status" do
    assert_equal "Draft", @offer.status_label
  end

  test "status_color returns appropriate color" do
    assert_equal "gray", @offer.status_color
    assert_equal "green", offers(:accepted_offer).status_color
  end

  # Scopes
  test "drafts scope returns only draft offers" do
    drafts = Offer.drafts
    drafts.each { |o| assert o.draft? }
  end

  test "active scope returns non-terminal offers" do
    active = Offer.active
    active.each { |o| assert_not o.accepted? && !o.declined? }
  end
end
