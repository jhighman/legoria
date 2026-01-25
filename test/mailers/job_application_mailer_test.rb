# frozen_string_literal: true

require "test_helper"

class JobApplicationMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: "localhost", port: 3000 }
  end

  def setup
    @organization = organizations(:acme)
    @job = jobs(:open_job)
    @first_stage = @job.stages.ordered.first

    # Create a fresh candidate for email tests to avoid duplicate application error
    @candidate = Candidate.create!(
      organization: @organization,
      first_name: "Mailer",
      last_name: "Test",
      email: "mailer.test.#{SecureRandom.hex(4)}@example.com"
    )

    @application = Application.create!(
      organization: @organization,
      job: @job,
      candidate: @candidate,
      current_stage: @first_stage,
      source_type: "career_site",
      applied_at: Time.current,
      last_activity_at: Time.current,
      tracking_token: "test-token-12345"
    )
  end

  test "application_received sends email to candidate" do
    email = JobApplicationMailer.application_received(@application)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [@candidate.email], email.to
    assert_match @job.title, email.subject
    assert_match @organization.name, email.subject
  end

  test "application_received includes tracking token" do
    email = JobApplicationMailer.application_received(@application)

    assert_match @application.tracking_token, email.body.encoded
  end

  test "application_received includes job details" do
    email = JobApplicationMailer.application_received(@application)

    assert_match @job.title, email.body.encoded
    assert_match @organization.name, email.body.encoded
  end

  test "application_received includes status link" do
    email = JobApplicationMailer.application_received(@application)

    # Check that the tracking token appears in the email body
    assert_match @application.tracking_token, email.body.encoded
    assert_match "/application/status/", email.body.encoded
  end

  test "status_update sends email to candidate" do
    email = JobApplicationMailer.status_update(@application)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [@candidate.email], email.to
  end

  test "status_update includes current status" do
    @application.update_column(:status, "screening")
    email = JobApplicationMailer.status_update(@application)

    assert_match "Screening", email.body.encoded
  end

  test "rejection_notice sends email to candidate" do
    email = JobApplicationMailer.rejection_notice(@application)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [@candidate.email], email.to
    assert_match "Application Update", email.subject
  end

  test "rejection_notice includes encouragement to apply again" do
    email = JobApplicationMailer.rejection_notice(@application)

    assert_match "encourage you to apply", email.body.encoded
  end

  test "rejection_notice includes link to careers page" do
    email = JobApplicationMailer.rejection_notice(@application)

    # Check that careers path is included
    assert_match "/careers", email.body.encoded
    assert_match "View Open Positions", email.body.encoded
  end
end
