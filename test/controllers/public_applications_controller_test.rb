# frozen_string_literal: true

require "test_helper"

class PublicApplicationsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  def setup
    @organization = organizations(:acme)
    @open_job = jobs(:open_job)
    @first_stage = @open_job.stages.ordered.first
  end

  # New action tests
  test "new displays application form without authentication" do
    get apply_career_url(@open_job)
    assert_response :success
    assert_select "h4", /Apply for #{@open_job.title}/
  end

  test "new shows required fields" do
    get apply_career_url(@open_job)
    assert_response :success
    # Check for labeled form fields
    assert_select "label", /First Name/
    assert_select "label", /Last Name/
    assert_select "label", /Email/
    assert_select "label", /Resume/
  end

  # Create action tests
  test "create creates new candidate and application" do
    assert_difference ["Candidate.count", "Application.count"], 1 do
      post apply_career_url(@open_job), params: {
        candidate: {
          first_name: "Jane",
          last_name: "Doe",
          email: "jane.doe@example.com",
          phone: "555-1234"
        },
        resume: fixture_file_upload("test/fixtures/files/resume.pdf", "application/pdf")
      }
    end

    application = Application.last
    assert_redirected_to application_status_check_path(application.tracking_token)
    assert_equal "new", application.status
    assert_equal @first_stage, application.current_stage
    assert_equal "career_site", application.source_type
  end

  test "create generates unique tracking token" do
    post apply_career_url(@open_job), params: {
      candidate: {
        first_name: "John",
        last_name: "Smith",
        email: "john.smith@example.com"
      },
      resume: fixture_file_upload("test/fixtures/files/resume.pdf", "application/pdf")
    }

    application = Application.last
    assert_not_nil application.tracking_token
    assert application.tracking_token.length >= 16
  end

  test "create sends confirmation email" do
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      post apply_career_url(@open_job), params: {
        candidate: {
          first_name: "Email",
          last_name: "Test",
          email: "email.test@example.com"
        },
        resume: fixture_file_upload("test/fixtures/files/resume.pdf", "application/pdf")
      }
    end
  end

  test "create with referral code sets source detail" do
    post apply_career_url(@open_job), params: {
      candidate: {
        first_name: "Referred",
        last_name: "Candidate",
        email: "referred@example.com"
      },
      referral_code: "REF123",
      resume: fixture_file_upload("test/fixtures/files/resume.pdf", "application/pdf")
    }

    application = Application.last
    assert_equal "REF123", application.source_detail
  end

  test "create with existing email updates candidate info" do
    existing = Candidate.create!(
      organization: @organization,
      first_name: "Existing",
      last_name: "Candidate",
      email: "existing@example.com"
    )

    assert_no_difference "Candidate.count" do
      assert_difference "Application.count", 1 do
        post apply_career_url(@open_job), params: {
          candidate: {
            first_name: "Updated",
            last_name: "Name",
            email: "existing@example.com",
            current_company: "New Company"
          },
          resume: fixture_file_upload("test/fixtures/files/resume.pdf", "application/pdf")
        }
      end
    end

    existing.reload
    assert_equal "Updated", existing.first_name
    assert_equal "New Company", existing.current_company
  end

  test "create fails without required fields" do
    assert_no_difference ["Candidate.count", "Application.count"] do
      post apply_career_url(@open_job), params: {
        candidate: {
          first_name: "",
          last_name: "",
          email: ""
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # Status lookup tests
  test "status_lookup displays form" do
    get application_status_url
    assert_response :success
    assert_select "input[name='token']"
  end

  # Status tests
  test "status displays application status with valid token" do
    application = create_application_with_token

    get application_status_check_url(application.tracking_token)
    assert_response :success
    assert_select "h4", @open_job.title
  end

  test "status shows timeline of events" do
    application = create_application_with_token

    get application_status_check_url(application.tracking_token)
    assert_response :success
    assert_select ".timeline"
  end

  test "status redirects with invalid token" do
    get application_status_check_url("invalid-token-12345")
    assert_redirected_to application_status_path
    assert_equal "Application not found. Please check your tracking code.", flash[:alert]
  end

  test "status shows appropriate message for each status" do
    application = create_application_with_token

    get application_status_check_url(application.tracking_token)
    assert_response :success
    assert_select ".alert-info", /Application Received/
  end

  private

  def create_application_with_token
    candidate = Candidate.create!(
      organization: @organization,
      first_name: "Status",
      last_name: "Test",
      email: "status.test@example.com"
    )

    Application.create!(
      organization: @organization,
      job: @open_job,
      candidate: candidate,
      current_stage: @first_stage,
      source_type: "career_site",
      applied_at: Time.current,
      last_activity_at: Time.current,
      tracking_token: SecureRandom.urlsafe_base64(16)
    )
  end
end
