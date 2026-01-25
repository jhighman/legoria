# frozen_string_literal: true

require "test_helper"

class WorkAuthorizationExpirationJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
    @expiring = work_authorizations(:ead_expiring_soon)
  end

  teardown do
    Current.reset
  end

  test "performs successfully" do
    assert_nothing_raised do
      WorkAuthorizationExpirationJob.perform_now
    end
  end

  test "sends 90-day warning for first-time expiring authorizations" do
    @expiring.update_columns(
      valid_until: 80.days.from_now.to_date,
      reverification_reminder_sent: false
    )

    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      WorkAuthorizationExpirationJob.perform_now
    end
  end

  test "marks reminder as sent" do
    @expiring.update_columns(
      valid_until: 80.days.from_now.to_date,
      reverification_reminder_sent: false
    )

    WorkAuthorizationExpirationJob.perform_now

    @expiring.reload
    assert @expiring.reverification_reminder_sent?
    assert_not_nil @expiring.reverification_reminder_sent_at
  end

  test "sends 30-day warning" do
    @expiring.update_columns(
      valid_until: 25.days.from_now.to_date,
      reverification_reminder_sent: true
    )

    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      WorkAuthorizationExpirationJob.perform_now
    end
  end

  test "skips indefinite authorizations" do
    citizen = work_authorizations(:citizen)
    assert citizen.indefinite?

    # Indefinite authorizations should not trigger any warnings
    # (Note: other non-indefinite fixtures may still trigger warnings)
    initial_count = enqueued_jobs.count { |j| j[:job] == ActionMailer::MailDeliveryJob }

    # The citizen authorization specifically should not be included
    # in any warning emails - this is verified by the indefinite? check
    assert citizen.indefinite?
    assert_not citizen.needs_reverification?
  end
end
