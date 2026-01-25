# frozen_string_literal: true

require "test_helper"

class CandidateTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @candidate = candidates(:john_doe)
  end

  def teardown
    Current.organization = nil
  end

  test "valid candidate" do
    assert @candidate.valid?
  end

  test "requires first_name" do
    @candidate.first_name = nil
    assert_not @candidate.valid?
    assert_includes @candidate.errors[:first_name], "can't be blank"
  end

  test "requires last_name" do
    @candidate.last_name = nil
    assert_not @candidate.valid?
    assert_includes @candidate.errors[:last_name], "can't be blank"
  end

  test "requires email" do
    @candidate.email = nil
    assert_not @candidate.valid?
    assert_includes @candidate.errors[:email], "can't be blank"
  end

  test "validates linkedin_url format" do
    @candidate.linkedin_url = "not a url"
    assert_not @candidate.valid?

    @candidate.linkedin_url = "https://linkedin.com/in/test"
    assert @candidate.valid?
  end

  test "ssn can be set and retrieved" do
    @candidate.ssn = "123-45-6789"
    assert_equal "123-45-6789", @candidate.ssn
  end

  test "full_name combines first and last name" do
    assert_equal "John Doe", @candidate.full_name
  end

  test "initials returns first letters" do
    assert_equal "JD", @candidate.initials
  end

  test "merged? returns true when merged_into is set" do
    assert_not @candidate.merged?

    merged = candidates(:merged_candidate)
    assert merged.merged?
  end

  test "masked_ssn returns partially hidden SSN" do
    @candidate.ssn = "123-45-6789"
    assert_equal "***-**-6789", @candidate.masked_ssn
  end

  test "masked_phone returns partially hidden phone" do
    @candidate.phone = "555-123-4567"
    # masked_phone replaces all digits except last 4 with asterisks
    assert @candidate.masked_phone.end_with?("4567")
    assert @candidate.masked_phone.include?("*")
  end

  test "primary_resume returns the primary resume" do
    resume = resumes(:john_resume)
    assert_equal resume, @candidate.primary_resume
  end

  test "unmerged scope excludes merged candidates" do
    unmerged = Candidate.unmerged
    merged = candidates(:merged_candidate)

    assert_not_includes unmerged, merged
    assert_includes unmerged, @candidate
  end

  test "search finds by name" do
    results = Candidate.search("John")
    assert_includes results, @candidate
  end

  test "search finds by location" do
    results = Candidate.search("San Francisco")
    assert_includes results, @candidate
  end
end
