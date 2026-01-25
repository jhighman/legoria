# frozen_string_literal: true

require "test_helper"

class ResumeTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @resume = resumes(:john_resume)
  end

  def teardown
    Current.organization = nil
  end

  test "valid resume" do
    assert @resume.valid?
  end

  test "requires filename" do
    @resume.filename = nil
    assert_not @resume.valid?
    assert_includes @resume.errors[:filename], "can't be blank"
  end

  test "requires content_type" do
    @resume.content_type = nil
    assert_not @resume.valid?
    assert_includes @resume.errors[:content_type], "can't be blank"
  end

  test "requires file_size" do
    @resume.file_size = nil
    assert_not @resume.valid?
  end

  test "validates file_size is positive" do
    @resume.file_size = 0
    assert_not @resume.valid?
  end

  test "validates file_size maximum" do
    @resume.file_size = 11.megabytes
    assert_not @resume.valid?
  end

  test "requires storage_key" do
    @resume.storage_key = nil
    assert_not @resume.valid?
  end

  test "validates storage_key uniqueness" do
    duplicate = Resume.new(
      candidate: @resume.candidate,
      filename: "duplicate.pdf",
      content_type: "application/pdf",
      file_size: 1024,
      storage_key: @resume.storage_key
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:storage_key], "has already been taken"
  end

  test "validates acceptable file types" do
    @resume.content_type = "application/pdf"
    assert @resume.valid?

    @resume.content_type = "image/jpeg"
    assert_not @resume.valid?
    assert_includes @resume.errors[:file], "must be a PDF, Word document, or text file"
  end

  test "file_type_label returns readable label" do
    assert_equal "PDF", @resume.file_type_label

    docx = resumes(:john_old_resume)
    assert_equal "Word (DOCX)", docx.file_type_label
  end

  test "file_size_formatted returns human-readable size" do
    @resume.file_size = 500
    assert_equal "500 B", @resume.file_size_formatted

    @resume.file_size = 2048
    assert_equal "2.0 KB", @resume.file_size_formatted

    @resume.file_size = 2.5.megabytes
    assert_equal "2.5 MB", @resume.file_size_formatted
  end

  test "parsed? returns true when parsed_at is set" do
    assert_not @resume.parsed?

    @resume.parsed_at = Time.current
    assert @resume.parsed?
  end

  test "mark_as_parsed! sets parsed fields" do
    @resume.mark_as_parsed!(text: "Resume content", data: { skills: ["Ruby"] })

    assert @resume.parsed?
    assert_equal "Resume content", @resume.raw_text
    assert_equal({ "skills" => ["Ruby"] }, @resume.parsed_data)
  end

  test "make_primary! sets this resume as primary and others as not primary" do
    other_resume = resumes(:john_old_resume)

    other_resume.make_primary!
    @resume.reload
    other_resume.reload

    assert other_resume.primary?
    assert_not @resume.primary?
  end

  test "primary_first scope orders primary resumes first" do
    candidate = candidates(:john_doe)
    resumes = candidate.resumes.primary_first

    primary_resumes = resumes.select(&:primary?)
    non_primary_resumes = resumes.reject(&:primary?)

    if primary_resumes.any? && non_primary_resumes.any?
      assert resumes.index(primary_resumes.first) < resumes.index(non_primary_resumes.first)
    end
  end
end
