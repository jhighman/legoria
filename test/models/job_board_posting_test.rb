# frozen_string_literal: true

require "test_helper"

class JobBoardPostingTest < ActiveSupport::TestCase
  def setup
    @posting = job_board_postings(:indeed_posting)
  end

  # Validations
  test "valid job board posting" do
    assert @posting.valid?
  end

  test "requires board_name" do
    @posting.board_name = nil
    assert_not @posting.valid?
    assert_includes @posting.errors[:board_name], "can't be blank"
  end

  test "validates status inclusion" do
    @posting.status = "invalid"
    assert_not @posting.valid?
    assert_includes @posting.errors[:status], "is not included in the list"
  end

  # Associations
  test "belongs to job" do
    assert_respond_to @posting, :job
    assert_equal jobs(:open_job), @posting.job
  end

  test "belongs to organization (optional)" do
    assert_respond_to @posting, :organization
    assert_equal organizations(:acme), @posting.organization
  end

  test "belongs to integration (optional)" do
    assert_respond_to @posting, :integration
    assert_equal integrations(:indeed_integration), @posting.integration
  end

  # Status methods
  test "pending? returns true for pending status" do
    posting = job_board_postings(:pending_posting)
    assert posting.pending?
  end

  test "active? returns true for active statuses" do
    assert @posting.active? # status: posted

    @posting.status = "active"
    assert @posting.active?

    @posting.status = "updated"
    assert @posting.active?
  end

  test "expired? returns true for expired status" do
    posting = job_board_postings(:expired_posting)
    assert posting.expired?
  end

  test "expired? returns true when expires_at is in the past" do
    @posting.status = "posted"
    @posting.expires_at = 1.day.ago
    assert @posting.expired?
  end

  test "failed? returns true for error statuses" do
    posting = job_board_postings(:failed_posting)
    assert posting.failed?
  end

  # Workflow methods
  test "mark_posted! updates posting details" do
    posting = job_board_postings(:pending_posting)
    posting.mark_posted!(
      external_id: "new_123",
      external_url: "https://example.com/new_123",
      expires_at: 30.days.from_now
    )

    assert_equal "posted", posting.status
    assert_equal "new_123", posting.external_id
    assert_not_nil posting.posted_at
    assert_not_nil posting.last_synced_at
    assert_nil posting.last_error
  end

  test "mark_updated! sets status" do
    @posting.mark_updated!

    assert_equal "updated", @posting.status
    assert_not_nil @posting.last_synced_at
  end

  test "mark_expired! sets status" do
    @posting.mark_expired!

    assert_equal "expired", @posting.status
  end

  test "mark_removed! sets status and timestamp" do
    @posting.mark_removed!

    assert_equal "removed", @posting.status
    assert_not_nil @posting.removed_at
  end

  test "mark_error! sets status and error message" do
    @posting.mark_error!("API error")

    assert_equal "error", @posting.status
    assert_equal "API error", @posting.last_error
  end

  test "update_stats! updates counts" do
    @posting.update_stats!(views: 2000, clicks: 150, applications: 25)

    assert_equal 2000, @posting.views_count
    assert_equal 150, @posting.clicks_count
    assert_equal 25, @posting.applications_count
    assert_not_nil @posting.last_synced_at
  end

  test "sync_needed? returns true when never synced" do
    @posting.last_synced_at = nil
    assert @posting.sync_needed?
  end

  test "sync_needed? returns true when stale" do
    @posting.last_synced_at = 2.hours.ago
    assert @posting.sync_needed?
  end

  test "sync_needed? returns false when recently synced" do
    @posting.last_synced_at = 30.minutes.ago
    assert_not @posting.sync_needed?
  end

  test "check_expiration! marks expired when past expires_at" do
    @posting.expires_at = 1.day.ago
    @posting.status = "posted"
    @posting.check_expiration!

    assert @posting.expired?
  end

  # Scopes
  test "active scope returns active postings" do
    active = JobBoardPosting.active
    assert active.include?(@posting)
    assert_not active.include?(job_board_postings(:expired_posting))
  end

  test "pending scope returns pending postings" do
    pending = JobBoardPosting.pending
    assert pending.include?(job_board_postings(:pending_posting))
    assert_not pending.include?(@posting)
  end

  test "failed scope returns failed postings" do
    failed = JobBoardPosting.failed
    assert failed.include?(job_board_postings(:failed_posting))
    assert_not failed.include?(@posting)
  end

  test "for_board scope filters by board name" do
    indeed = JobBoardPosting.for_board("indeed")
    assert indeed.include?(@posting)
    assert_not indeed.include?(job_board_postings(:linkedin_posting))
  end
end
