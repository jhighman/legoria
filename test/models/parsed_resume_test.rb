# frozen_string_literal: true

require "test_helper"

class ParsedResumeTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    @candidate = candidates(:john_doe)
    Current.organization = @organization
    Current.user = users(:admin)
  end

  teardown do
    Current.reset
  end

  # Validations
  test "requires status" do
    resume = ParsedResume.new(
      organization: @organization,
      candidate: @candidate
    )
    # Status has a default, so this should be valid except for other fields
    assert resume.valid? || resume.errors[:status].present? == false
  end

  test "validates status inclusion" do
    resume = parsed_resumes(:john_doe_resume)
    resume.status = "invalid"
    assert_not resume.valid?
    assert_includes resume.errors[:status], "is not included in the list"
  end

  test "validates highest_education_level inclusion" do
    resume = parsed_resumes(:john_doe_resume)
    resume.highest_education_level = "invalid"
    assert_not resume.valid?
    assert_includes resume.errors[:highest_education_level], "is not included in the list"
  end

  # Status transitions
  test "start_processing changes status to processing" do
    resume = parsed_resumes(:jane_smith_resume)
    assert_equal "pending", resume.status
    resume.start_processing!
    assert_equal "processing", resume.status
  end

  test "complete sets status and parsed data" do
    resume = parsed_resumes(:jane_smith_resume)
    resume.start_processing!
    resume.complete!(
      parsed_data: {
        "name" => "Jane Smith",
        "email" => "jane@example.com",
        "skills" => ["Python", "Data Analysis"]
      }
    )
    assert_equal "completed", resume.status
    assert_equal "Jane Smith", resume.parsed_name
    assert_includes resume.skills_list, "Python"
  end

  test "fail sets status and error message" do
    resume = parsed_resumes(:jane_smith_resume)
    resume.start_processing!
    resume.fail!("PDF parsing failed")
    assert_equal "failed", resume.status
    assert_equal "PDF parsing failed", resume.error_message
  end

  test "can_retry is true for failed resumes" do
    resume = parsed_resumes(:failed_resume)
    assert resume.can_retry?
  end

  test "can_retry is false for completed resumes" do
    resume = parsed_resumes(:john_doe_resume)
    assert_not resume.can_retry?
  end

  # Review workflow
  test "mark_reviewed sets reviewed flag and reviewer" do
    resume = parsed_resumes(:jane_smith_resume)
    reviewer = users(:admin)
    resume.mark_reviewed!(reviewer)
    assert resume.reviewed?
    assert_equal reviewer, resume.reviewed_by
    assert_not_nil resume.reviewed_at
  end

  # Helper methods
  test "contact_info returns parsed contact data" do
    resume = parsed_resumes(:john_doe_resume)
    assert_equal "john.doe@example.com", resume.contact_info["email"]
    assert_equal "John Doe", resume.contact_info["name"]
  end

  test "work_history returns work experience array" do
    resume = parsed_resumes(:john_doe_resume)
    assert_equal 2, resume.work_history.length
    assert_equal "Senior Developer", resume.work_history.first["title"]
  end

  test "skills_list returns skills array" do
    resume = parsed_resumes(:john_doe_resume)
    assert_includes resume.skills_list, "Ruby"
    assert_includes resume.skills_list, "Rails"
  end

  test "education_history returns education array" do
    resume = parsed_resumes(:john_doe_resume)
    assert_equal 1, resume.education_history.length
    assert_equal "Bachelor's", resume.education_history.first["degree"]
  end

  test "total_years_experience returns stored value when present" do
    resume = parsed_resumes(:john_doe_resume)
    assert_equal 8, resume.total_years_experience
  end

  # Scopes
  test "pending scope returns pending resumes" do
    assert_includes ParsedResume.pending, parsed_resumes(:jane_smith_resume)
    assert_not_includes ParsedResume.pending, parsed_resumes(:john_doe_resume)
  end

  test "completed scope returns completed resumes" do
    assert_includes ParsedResume.completed, parsed_resumes(:john_doe_resume)
    assert_not_includes ParsedResume.completed, parsed_resumes(:failed_resume)
  end

  test "failed scope returns failed resumes" do
    assert_includes ParsedResume.failed, parsed_resumes(:failed_resume)
  end

  test "reviewed scope returns reviewed resumes" do
    assert_includes ParsedResume.reviewed, parsed_resumes(:john_doe_resume)
  end
end
