# frozen_string_literal: true

require "test_helper"

class WebhookDeliveryTest < ActiveSupport::TestCase
  def setup
    @delivery = webhook_deliveries(:delivered_application_event)
    @pending = webhook_deliveries(:pending_delivery)
    @failed = webhook_deliveries(:failed_delivery)
    @retrying = webhook_deliveries(:retrying_delivery)
  end

  # Validations
  test "valid webhook delivery" do
    assert @delivery.valid?
  end

  test "requires event_type" do
    @pending.event_type = nil
    assert_not @pending.valid?
    assert_includes @pending.errors[:event_type], "can't be blank"
  end

  test "requires event_id" do
    @pending.event_id = nil
    assert_not @pending.valid?
    assert_includes @pending.errors[:event_id], "can't be blank"
  end

  test "requires unique event_id" do
    duplicate = @pending.dup
    duplicate.event_id = @delivery.event_id
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:event_id], "has already been taken"
  end

  # Associations
  test "belongs to organization" do
    assert_respond_to @delivery, :organization
    assert_equal organizations(:acme), @delivery.organization
  end

  test "belongs to webhook" do
    assert_respond_to @delivery, :webhook
    assert_equal webhooks(:application_webhook), @delivery.webhook
  end

  # Status methods
  test "pending? returns true for pending status" do
    assert @pending.pending?
    assert_not @delivery.pending?
  end

  test "delivered? returns true for success status" do
    assert @delivery.delivered?
    assert_not @pending.delivered?
  end

  test "failed? returns true for failed status" do
    assert @failed.failed?
    assert_not @delivery.failed?
  end

  test "retrying? returns true for retrying status" do
    assert @retrying.retrying?
    assert_not @delivery.retrying?
  end

  # Retry logic
  test "can_retry? returns true when under max attempts" do
    @pending.attempt_count = 2
    assert @pending.can_retry?
  end

  test "can_retry? returns false at max attempts" do
    @pending.attempt_count = 5
    assert_not @pending.can_retry?
  end

  test "can_retry? returns false when delivered" do
    assert_not @delivery.can_retry?
  end

  # Workflow methods
  test "mark_sending! updates status" do
    @pending.mark_sending!
    assert_equal "sending", @pending.status
  end

  test "mark_delivered! updates status and timestamps" do
    @pending.mark_sending!
    @pending.mark_delivered!(response_status: 200, response_time_ms: 150)

    assert @pending.delivered?
    assert_equal 200, @pending.response_status
    assert_equal 150, @pending.response_time_ms
    assert_not_nil @pending.delivered_at
  end

  test "mark_failed! schedules retry when possible" do
    @pending.mark_sending!
    @pending.mark_failed!(response_status: 500, error_message: "Server error")

    assert @pending.retrying?
    assert_equal 1, @pending.attempt_count
    assert_not_nil @pending.next_retry_at
  end

  test "mark_failed! sets failed status at max attempts" do
    @retrying.attempt_count = 4 # One more attempt will hit max
    @retrying.mark_failed!(response_status: 500)

    assert @retrying.failed?
    assert_equal 5, @retrying.attempt_count
  end

  test "schedule_retry! calculates exponential backoff" do
    @pending.attempt_count = 1
    @pending.schedule_retry!

    # First retry should be ~1 minute
    assert @pending.retrying?
    assert_in_delta 60.seconds.from_now, @pending.next_retry_at, 5.seconds
  end

  # Class methods
  test "create_for_event creates delivery" do
    webhook = webhooks(:application_webhook)

    delivery = WebhookDelivery.create_for_event(
      webhook: webhook,
      event_type: "application.hired",
      payload: { application_id: 1 }
    )

    assert delivery.persisted?
    assert_equal webhook.organization, delivery.organization
    assert_equal "application.hired", delivery.event_type
    assert_equal "pending", delivery.status
    assert_equal 0, delivery.attempt_count
  end

  # Scopes
  test "pending scope returns pending deliveries" do
    pending = WebhookDelivery.pending
    assert pending.include?(@pending)
    assert_not pending.include?(@delivery)
  end

  test "needs_retry scope returns deliveries ready to retry" do
    @retrying.update!(next_retry_at: 1.minute.ago)
    needs_retry = WebhookDelivery.needs_retry
    assert needs_retry.include?(@retrying)
  end
end
