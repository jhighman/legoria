# frozen_string_literal: true

require "test_helper"

class I9VerificationPolicyTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    @admin = users(:admin)
    @recruiter = users(:recruiter)
    @hiring_manager = users(:hiring_manager)
    @verification = i9_verifications(:pending_section1)
  end

  test "admin can view all verifications in organization" do
    policy = I9VerificationPolicy.new(@admin, @verification)
    assert policy.index?
    assert policy.show?
  end

  test "recruiter can view all verifications in organization" do
    policy = I9VerificationPolicy.new(@recruiter, @verification)
    assert policy.index?
    assert policy.show?
  end

  test "admin can create verifications" do
    policy = I9VerificationPolicy.new(@admin, @verification)
    assert policy.create?
  end

  test "recruiter can create verifications" do
    policy = I9VerificationPolicy.new(@recruiter, @verification)
    assert policy.create?
  end

  test "admin can update verifications" do
    policy = I9VerificationPolicy.new(@admin, @verification)
    assert policy.update?
  end

  test "recruiter can update verifications" do
    policy = I9VerificationPolicy.new(@recruiter, @verification)
    assert policy.update?
  end

  test "verifications cannot be destroyed for compliance" do
    policy = I9VerificationPolicy.new(@admin, @verification)
    assert_not policy.destroy?
  end

  test "admin can complete section2" do
    @verification.update_columns(status: "section1_complete")
    policy = I9VerificationPolicy.new(@admin, @verification)
    assert policy.section2?
    assert policy.complete_section2?
  end

  test "recruiter can complete section2" do
    @verification.update_columns(status: "section1_complete")
    policy = I9VerificationPolicy.new(@recruiter, @verification)
    assert policy.section2?
    assert policy.complete_section2?
  end

  test "section2 requires section1_complete status" do
    @verification.update_columns(status: "pending_section1")
    policy = I9VerificationPolicy.new(@admin, @verification)
    assert_not policy.section2?
  end

  test "admin can complete section3 for verified verifications" do
    @verification.update_columns(status: "verified")
    policy = I9VerificationPolicy.new(@admin, @verification)
    assert policy.section3?
    assert policy.complete_section3?
  end

  test "section3 requires verified status" do
    @verification.update_columns(status: "section1_complete")
    policy = I9VerificationPolicy.new(@admin, @verification)
    assert_not policy.section3?
  end

  test "admin can view pending verifications" do
    policy = I9VerificationPolicy.new(@admin, @verification)
    assert policy.pending?
    assert policy.overdue?
  end

  test "hiring manager can view verifications for their jobs" do
    # First ensure the hiring manager is assigned to the job
    job = @verification.application.job
    job.update!(hiring_manager: @hiring_manager)

    policy = I9VerificationPolicy.new(@hiring_manager, @verification)
    assert policy.show?
  end

  test "scope returns verifications for admin" do
    Current.organization = @organization
    scope = I9VerificationPolicy::Scope.new(@admin, I9Verification).resolve
    assert_includes scope, @verification
  end

  test "scope returns verifications for recruiter" do
    Current.organization = @organization
    scope = I9VerificationPolicy::Scope.new(@recruiter, I9Verification).resolve
    assert_includes scope, @verification
  end
end
