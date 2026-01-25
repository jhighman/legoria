# frozen_string_literal: true

require "test_helper"

class CompleteI9Section2ServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @organization = organizations(:acme)
    Current.organization = @organization
    @user = users(:admin)
    @verification = i9_verifications(:section1_complete)
  end

  teardown do
    Current.reset
  end

  test "completes section 2 with valid list A document" do
    result = CompleteI9Section2Service.call(
      i9_verification: @verification,
      section2_params: {
        employer_title: "HR Manager",
        employer_organization_name: "Acme Corp",
        employer_organization_address: "123 Main St, City, ST 12345"
      },
      documents: [
        {
          list_type: "list_a",
          document_type: "us_passport",
          document_number: "123456789",
          expiration_date: 5.years.from_now.to_date
        }
      ],
      completed_by: @user,
      ip_address: "10.0.0.1"
    )

    assert result.success?
    @verification.reload
    assert_equal "verified", @verification.status
    assert_not_nil @verification.section2_completed_at
    assert_equal @user, @verification.section2_completed_by
  end

  test "completes section 2 with list B + C documents" do
    result = CompleteI9Section2Service.call(
      i9_verification: @verification,
      section2_params: {
        employer_title: "HR Manager",
        employer_organization_name: "Acme Corp",
        employer_organization_address: "123 Main St, City, ST 12345"
      },
      documents: [
        {
          list_type: "list_b",
          document_type: "drivers_license",
          document_number: "D1234567",
          expiration_date: 3.years.from_now.to_date
        },
        {
          list_type: "list_c",
          document_type: "social_security_card",
          document_number: "123-45-6789"
        }
      ],
      completed_by: @user,
      ip_address: "10.0.0.1"
    )

    assert result.success?
  end

  test "creates work authorization" do
    CompleteI9Section2Service.call(
      i9_verification: @verification,
      section2_params: {
        employer_title: "HR Manager",
        employer_organization_name: "Acme Corp",
        employer_organization_address: "123 Main St, City, ST 12345"
      },
      documents: [
        {
          list_type: "list_a",
          document_type: "us_passport",
          document_number: "123456789"
        }
      ],
      completed_by: @user,
      ip_address: "10.0.0.1"
    )

    @verification.reload
    work_auth = WorkAuthorization.find_by(i9_verification: @verification)
    assert_not_nil work_auth
    assert_equal "citizen", work_auth.authorization_type
    assert work_auth.indefinite?
  end

  test "fails without employer title" do
    result = CompleteI9Section2Service.call(
      i9_verification: @verification,
      section2_params: {
        employer_organization_name: "Acme Corp",
        employer_organization_address: "123 Main St"
      },
      documents: [{ list_type: "list_a", document_type: "us_passport", document_number: "123" }],
      completed_by: @user,
      ip_address: "10.0.0.1"
    )

    assert result.failure?
    assert_equal :employer_title_required, result.failure
  end

  test "fails without documents" do
    result = CompleteI9Section2Service.call(
      i9_verification: @verification,
      section2_params: {
        employer_title: "HR Manager",
        employer_organization_name: "Acme Corp",
        employer_organization_address: "123 Main St"
      },
      documents: [],
      completed_by: @user,
      ip_address: "10.0.0.1"
    )

    assert result.failure?
    assert_equal :no_documents_provided, result.failure
  end

  test "fails with only list B document" do
    result = CompleteI9Section2Service.call(
      i9_verification: @verification,
      section2_params: {
        employer_title: "HR Manager",
        employer_organization_name: "Acme Corp",
        employer_organization_address: "123 Main St"
      },
      documents: [
        { list_type: "list_b", document_type: "drivers_license", document_number: "D123" }
      ],
      completed_by: @user,
      ip_address: "10.0.0.1"
    )

    assert result.failure?
    assert_equal :invalid_document_combination, result.failure
  end

  test "marks late completion when past deadline" do
    @verification.update_column(:deadline_section2, Date.yesterday)

    CompleteI9Section2Service.call(
      i9_verification: @verification,
      section2_params: {
        employer_title: "HR Manager",
        employer_organization_name: "Acme Corp",
        employer_organization_address: "123 Main St"
      },
      documents: [
        { list_type: "list_a", document_type: "us_passport", document_number: "123" }
      ],
      completed_by: @user,
      ip_address: "10.0.0.1"
    )

    @verification.reload
    assert @verification.late_completion?
    assert_not_nil @verification.late_completion_reason
  end

  test "queues notification job" do
    assert_enqueued_with(job: I9NotificationJob) do
      CompleteI9Section2Service.call(
        i9_verification: @verification,
        section2_params: {
          employer_title: "HR Manager",
          employer_organization_name: "Acme Corp",
          employer_organization_address: "123 Main St"
        },
        documents: [
          { list_type: "list_a", document_type: "us_passport", document_number: "123" }
        ],
        completed_by: @user,
        ip_address: "10.0.0.1"
      )
    end
  end
end
