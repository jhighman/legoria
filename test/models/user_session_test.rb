# frozen_string_literal: true

require "test_helper"

class UserSessionTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
  end

  # Creation
  test "create_for_user creates valid session" do
    session, token = UserSession.create_for_user(
      @user,
      ip_address: "1.2.3.4",
      user_agent: "Mozilla/5.0"
    )

    assert session.persisted?
    assert_equal @user, session.user
    assert_equal "1.2.3.4", session.ip_address
    assert_equal "Mozilla/5.0", session.user_agent
    assert_not_nil session.token_digest
    assert_not_nil session.expires_at
    assert_not_nil session.last_active_at
    assert_not_nil token
  end

  test "create_for_user accepts custom expiry" do
    session, _ = UserSession.create_for_user(@user, expires_in: 1.hour)

    assert_in_delta 1.hour.from_now, session.expires_at, 5.seconds
  end

  # Authentication
  test "find_by_token finds valid session" do
    session, token = UserSession.create_for_user(@user)

    found = UserSession.find_by_token(token)

    assert_equal session, found
  end

  test "find_by_token returns nil for invalid token" do
    found = UserSession.find_by_token("invalid_token")

    assert_nil found
  end

  test "find_by_token returns nil for expired session" do
    session, token = UserSession.create_for_user(@user, expires_in: -1.hour)

    found = UserSession.find_by_token(token)

    assert_nil found
  end

  # Status methods
  test "active? returns true for valid session" do
    session, _ = UserSession.create_for_user(@user)

    assert session.active?
  end

  test "active? returns false for expired session" do
    session, _ = UserSession.create_for_user(@user)
    session.update!(expires_at: 1.hour.ago)

    assert_not session.active?
    assert session.expired?
  end

  # Instance methods
  test "touch_activity! updates last_active_at" do
    session, _ = UserSession.create_for_user(@user)
    old_time = session.last_active_at

    travel 1.minute do
      session.touch_activity!
    end

    assert session.last_active_at > old_time
  end

  test "extend! updates expires_at" do
    session, _ = UserSession.create_for_user(@user, expires_in: 1.hour)

    session.extend!(48.hours)

    assert_in_delta 48.hours.from_now, session.expires_at, 5.seconds
  end

  test "invalidate! sets expires_at to now" do
    session, _ = UserSession.create_for_user(@user)

    session.invalidate!

    assert session.expired?
  end

  # Cleanup
  test "cleanup_expired! removes expired sessions" do
    active, _ = UserSession.create_for_user(@user)
    expired, _ = UserSession.create_for_user(@user, expires_in: -1.hour)

    count = UserSession.cleanup_expired!

    assert count >= 1
    assert UserSession.exists?(active.id)
    assert_not UserSession.exists?(expired.id)
  end

  # Scopes
  test "active scope returns non-expired sessions" do
    active, _ = UserSession.create_for_user(@user)
    expired, _ = UserSession.create_for_user(@user, expires_in: -1.hour)

    sessions = UserSession.active

    assert sessions.include?(active)
    assert_not sessions.include?(expired)
  end

  test "expired scope returns expired sessions" do
    active, _ = UserSession.create_for_user(@user)
    expired, _ = UserSession.create_for_user(@user, expires_in: -1.hour)

    sessions = UserSession.expired

    assert_not sessions.include?(active)
    assert sessions.include?(expired)
  end
end
