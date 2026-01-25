# frozen_string_literal: true

require "test_helper"

class WebhookTest < ActiveSupport::TestCase
  def setup
    @webhook = webhooks(:application_webhook)
  end

  # Validations
  test "valid webhook" do
    assert @webhook.valid?
  end

  test "requires name" do
    @webhook.name = nil
    assert_not @webhook.valid?
    assert_includes @webhook.errors[:name], "can't be blank"
  end

  test "requires url" do
    @webhook.url = nil
    assert_not @webhook.valid?
    assert_includes @webhook.errors[:url], "can't be blank"
  end

  test "validates url format" do
    @webhook.url = "not-a-url"
    assert_not @webhook.valid?
    assert_includes @webhook.errors[:url], "is invalid"
  end

  test "accepts valid https url" do
    @webhook.url = "https://example.com/webhooks"
    assert @webhook.valid?
  end

  test "validates events" do
    @webhook.events = ["invalid.event"]
    assert_not @webhook.valid?
    assert_includes @webhook.errors[:events], "contains invalid types: invalid.event"
  end

  # Associations
  test "belongs to organization" do
    assert_respond_to @webhook, :organization
    assert_equal organizations(:acme), @webhook.organization
  end

  test "has many webhook_deliveries" do
    assert_respond_to @webhook, :webhook_deliveries
  end

  # Secret generation
  test "generates secret on create" do
    webhook = Webhook.create!(
      organization: organizations(:acme),
      created_by: users(:admin),
      name: "New Webhook",
      url: "https://example.com/new",
      events: ["application.created"]
    )
    assert_not_nil webhook.secret
    assert_equal 64, webhook.secret.length # hex(32) = 64 chars
  end

  # Instance methods
  test "subscribes_to? returns true for subscribed events" do
    assert @webhook.subscribes_to?("application.created")
    assert_not @webhook.subscribes_to?("offer.created")
  end

  test "active_for_delivery? checks both active and status" do
    assert @webhook.active_for_delivery?

    @webhook.status = "failing"
    assert_not @webhook.active_for_delivery?
  end

  test "pause! sets status to failing" do
    @webhook.pause!
    assert_equal "failing", @webhook.status
  end

  test "resume! sets status to active and resets failures" do
    failing = webhooks(:paused_webhook)
    failing.resume!
    assert_equal "active", failing.status
    assert_equal 0, failing.consecutive_failures
  end

  test "disable! sets status and active flag" do
    @webhook.disable!
    assert_equal "disabled", @webhook.status
    assert_not @webhook.active?
  end

  test "compute_signature generates HMAC" do
    payload = '{"test": "data"}'
    signature = @webhook.compute_signature(payload)
    assert_match(/\A[a-f0-9]{64}\z/, signature)
  end

  test "regenerate_secret! changes secret" do
    old_secret = @webhook.secret
    @webhook.regenerate_secret!
    assert_not_equal old_secret, @webhook.secret
  end

  # Scopes
  test "active scope returns active webhooks" do
    active = Webhook.active
    assert active.include?(@webhook)
    assert_not active.include?(webhooks(:disabled_webhook))
    assert_not active.include?(webhooks(:paused_webhook))
  end
end
