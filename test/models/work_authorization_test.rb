# frozen_string_literal: true

require "test_helper"

class WorkAuthorizationTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
    @citizen = work_authorizations(:citizen)
    @h1b = work_authorizations(:h1b_active)
    @expiring = work_authorizations(:ead_expiring_soon)
  end

  teardown do
    Current.reset
  end

  # Validations
  test "requires authorization_type" do
    auth = WorkAuthorization.new(
      organization: @organization,
      candidate: candidates(:john_doe),
      valid_from: Date.current
    )
    assert_not auth.valid?
    assert_includes auth.errors[:authorization_type], "can't be blank"
  end

  test "requires valid_from" do
    auth = WorkAuthorization.new(
      organization: @organization,
      candidate: candidates(:john_doe),
      authorization_type: "h1b"
    )
    assert_not auth.valid?
    assert_includes auth.errors[:valid_from], "can't be blank"
  end

  test "requires valid_until unless indefinite" do
    auth = WorkAuthorization.new(
      organization: @organization,
      candidate: candidates(:john_doe),
      authorization_type: "h1b",
      valid_from: Date.current,
      indefinite: false
    )
    assert_not auth.valid?
    assert_includes auth.errors[:valid_until], "can't be blank"
  end

  test "does not require valid_until when indefinite" do
    auth = WorkAuthorization.new(
      organization: @organization,
      candidate: candidates(:john_doe),
      authorization_type: "citizen",
      valid_from: Date.current
    )
    assert auth.valid?
  end

  test "valid_until must be after valid_from" do
    auth = WorkAuthorization.new(
      organization: @organization,
      candidate: candidates(:john_doe),
      authorization_type: "h1b",
      valid_from: Date.current,
      valid_until: Date.yesterday
    )
    assert_not auth.valid?
    assert_includes auth.errors[:valid_until], "must be after valid from date"
  end

  # Scopes
  test "active scope returns non-expired authorizations" do
    active = WorkAuthorization.active
    assert_includes active, @citizen
    assert_includes active, @h1b
  end

  test "expiring_soon scope returns authorizations expiring within days" do
    expiring = WorkAuthorization.expiring_soon(90)
    assert_includes expiring, @expiring
    assert_not_includes expiring, @h1b
  end

  # Status helpers
  test "expired? returns false for indefinite authorization" do
    assert_not @citizen.expired?
  end

  test "active? returns true for indefinite authorization" do
    assert @citizen.active?
  end

  test "expires_within? returns true when expiring within timeframe" do
    assert @expiring.expires_within?(60)
  end

  test "expires_within? returns false for indefinite" do
    assert_not @citizen.expires_within?(60)
  end

  test "days_until_expiration returns nil for indefinite" do
    assert_nil @citizen.days_until_expiration
  end

  test "days_until_expiration returns correct days" do
    days = @expiring.days_until_expiration
    assert days.is_a?(Integer)
    assert days > 0
  end

  test "needs_reverification? returns false for indefinite" do
    assert_not @citizen.needs_reverification?
  end

  test "needs_reverification? returns true when reverification_required" do
    assert @expiring.needs_reverification?
  end

  # Auto-indefinite for citizen types
  test "sets indefinite to true for citizen type" do
    auth = WorkAuthorization.new(
      organization: @organization,
      candidate: candidates(:john_doe),
      authorization_type: "citizen",
      valid_from: Date.current
    )
    auth.valid?
    assert auth.indefinite?
  end

  test "sets indefinite to true for permanent_resident type" do
    auth = WorkAuthorization.new(
      organization: @organization,
      candidate: candidates(:john_doe),
      authorization_type: "permanent_resident",
      valid_from: Date.current
    )
    auth.valid?
    assert auth.indefinite?
  end

  # Display helpers
  test "authorization_type_label returns human readable type" do
    assert_equal "U.S. Citizen", @citizen.authorization_type_label
    assert_equal "H-1B Visa", @h1b.authorization_type_label
  end

  test "status_label returns appropriate status" do
    assert_equal "Indefinite", @citizen.status_label
    assert_equal "Active", @h1b.status_label
    assert_equal "Expiring Soon", @expiring.status_label
  end

  test "validity_period returns Indefinite for indefinite auth" do
    assert_equal "Indefinite", @citizen.validity_period
  end
end
