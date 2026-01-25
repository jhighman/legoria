# frozen_string_literal: true

require "test_helper"

class CandidateDocumentTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @document = candidate_documents(:john_resume)
  end

  def teardown
    Current.organization = nil
  end

  test "requires name" do
    @document.name = nil
    assert_not @document.valid?
    assert_includes @document.errors[:name], "can't be blank"
  end

  test "requires document_type" do
    @document.document_type = nil
    assert_not @document.valid?
    assert_includes @document.errors[:document_type], "can't be blank"
  end

  test "validates document_type inclusion" do
    @document.document_type = "invalid"
    assert_not @document.valid?
    assert_includes @document.errors[:document_type], "is not included in the list"
  end

  # Type helpers
  test "resume? returns true for resumes" do
    assert @document.resume?
  end

  test "cover_letter? returns true for cover letters" do
    assert candidate_documents(:john_cover_letter).cover_letter?
  end

  test "portfolio? returns true for portfolios" do
    assert candidate_documents(:john_portfolio).portfolio?
  end

  # Display helpers
  test "document_type_label returns formatted type" do
    assert_equal "Resume", @document.document_type_label
  end

  test "file_size_formatted returns human-readable size" do
    @document.file_size = 1024 * 500 # 500 KB
    assert_equal "500.0 KB", @document.file_size_formatted
  end

  test "file_extension returns uppercase extension" do
    @document.original_filename = "resume.pdf"
    assert_equal "PDF", @document.file_extension
  end

  # Visibility
  test "toggle_visibility! switches visibility" do
    assert @document.visible_to_employer?
    @document.toggle_visibility!
    assert_not @document.reload.visible_to_employer?
  end

  test "hide! sets visibility to false" do
    @document.hide!
    assert_not @document.reload.visible_to_employer?
  end

  test "show! sets visibility to true" do
    hidden = candidate_documents(:hidden_document)
    hidden.show!
    assert hidden.reload.visible_to_employer?
  end

  # Scopes
  test "visible scope returns only visible documents" do
    visible = CandidateDocument.visible
    visible.each { |d| assert d.visible_to_employer? }
  end

  test "by_type scope filters by document type" do
    resumes = CandidateDocument.by_type("resume")
    resumes.each { |d| assert d.resume? }
  end
end
