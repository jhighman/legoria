# frozen_string_literal: true

require "test_helper"

class DeletionRequestTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @request = deletion_requests(:pending_request)
  end

  def teardown
    Current.organization = nil
  end

  test "valid request" do
    assert @request.valid?
  end

  test "requires request_source" do
    @request.request_source = nil
    assert_not @request.valid?
    assert_includes @request.errors[:request_source], "can't be blank"
  end

  test "validates status inclusion" do
    @request.status = "invalid"
    assert_not @request.valid?
    assert_includes @request.errors[:status], "is not included in the list"
  end

  test "validates request_source inclusion" do
    @request.request_source = "invalid"
    assert_not @request.valid?
    assert_includes @request.errors[:request_source], "is not included in the list"
  end

  # Status helpers
  test "pending? returns true for pending requests" do
    assert @request.pending?
  end

  test "completed? returns true for completed requests" do
    assert deletion_requests(:completed_request).completed?
  end

  test "can_process? returns true when verified and no hold" do
    verified = deletion_requests(:verified_request)
    assert verified.can_process?
  end

  test "can_process? returns false when on legal hold" do
    on_hold = deletion_requests(:on_hold_request)
    assert_not on_hold.can_process?
  end

  # Verification
  test "verify_identity! sets verified flag and timestamp" do
    @request.verify_identity!("email_confirmation")
    assert @request.identity_verified?
    assert @request.verified_at.present?
    assert_equal "email_confirmation", @request.verification_method
  end

  # Legal hold
  test "place_legal_hold! sets hold and reason" do
    @request.place_legal_hold!("Pending investigation")
    assert @request.legal_hold?
    assert_equal "Pending investigation", @request.legal_hold_reason
  end

  test "remove_legal_hold! clears hold" do
    on_hold = deletion_requests(:on_hold_request)
    on_hold.remove_legal_hold!
    assert_not on_hold.legal_hold?
  end

  # Display helpers
  test "status_label returns formatted status" do
    assert_equal "Pending", @request.status_label
  end

  test "status_color returns appropriate color" do
    assert_equal "yellow", @request.status_color
    assert_equal "green", deletion_requests(:completed_request).status_color
  end

  test "days_since_request returns day count" do
    @request.update_column(:requested_at, 10.days.ago)
    assert_equal 10, @request.days_since_request
  end

  test "past_deadline? returns true after 30 days" do
    @request.update_column(:requested_at, 35.days.ago)
    assert @request.past_deadline?
  end

  # Scopes
  test "pending scope returns only pending requests" do
    pending = DeletionRequest.pending
    pending.each { |r| assert r.pending? }
  end

  test "on_legal_hold scope returns only held requests" do
    held = DeletionRequest.on_legal_hold
    held.each { |r| assert r.legal_hold? }
  end
end
