# frozen_string_literal: true

require "test_helper"

class JobApprovalTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @approval = job_approvals(:pending_approval)
  end

  def teardown
    Current.organization = nil
  end

  test "valid job approval" do
    assert @approval.valid?
  end

  test "requires valid status" do
    @approval.status = "invalid"
    assert_not @approval.valid?
    assert_includes @approval.errors[:status], "is not included in the list"
  end

  test "valid statuses" do
    JobApproval::STATUSES.each do |status|
      @approval.status = status
      assert @approval.valid?, "Should be valid with status: #{status}"
    end
  end

  test "pending? returns true for pending status" do
    @approval.status = "pending"
    assert @approval.pending?
  end

  test "approved? returns true for approved status" do
    @approval.status = "approved"
    assert @approval.approved?
  end

  test "rejected? returns true for rejected status" do
    @approval.status = "rejected"
    assert @approval.rejected?
  end

  test "decided? returns true for non-pending status" do
    @approval.status = "pending"
    assert_not @approval.decided?

    @approval.status = "approved"
    assert @approval.decided?
  end

  test "approve! changes status and sets decided_at" do
    assert @approval.pending?
    @approval.approve!(notes: "Looks good!")

    assert @approval.approved?
    assert_not_nil @approval.decided_at
    assert_equal "Looks good!", @approval.notes
  end

  test "approve! returns false if not pending" do
    @approval.status = "approved"
    assert_not @approval.approve!
  end

  test "reject! changes status and sets decided_at" do
    assert @approval.pending?
    @approval.reject!(notes: "Needs changes")

    assert @approval.rejected?
    assert_not_nil @approval.decided_at
    assert_equal "Needs changes", @approval.notes
  end

  test "reject! returns false if not pending" do
    @approval.status = "rejected"
    assert_not @approval.reject!
  end

  test "pending scope returns only pending approvals" do
    JobApproval.pending.each do |approval|
      assert approval.pending?
    end
  end

  test "approved scope returns only approved approvals" do
    JobApproval.approved.each do |approval|
      assert approval.approved?
    end
  end

  test "decided scope returns non-pending approvals" do
    JobApproval.decided.each do |approval|
      assert approval.decided?
    end
  end
end
