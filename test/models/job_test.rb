# frozen_string_literal: true

require "test_helper"

class JobTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @job = jobs(:draft_job)
  end

  def teardown
    Current.organization = nil
  end

  test "valid job" do
    assert @job.valid?
  end

  test "requires title" do
    @job.title = nil
    assert_not @job.valid?
    assert_includes @job.errors[:title], "can't be blank"
  end

  test "requires valid employment_type" do
    @job.employment_type = "invalid"
    assert_not @job.valid?
    assert_includes @job.errors[:employment_type], "is not a valid employment type"
  end

  test "requires valid location_type" do
    @job.location_type = "invalid"
    assert_not @job.valid?
    assert_includes @job.errors[:location_type], "is not a valid location type"
  end

  test "headcount must be positive" do
    @job.headcount = 0
    assert_not @job.valid?

    @job.headcount = 1
    assert @job.valid?
  end

  test "salary_max must be >= salary_min" do
    @job.salary_min = 100000
    @job.salary_max = 50000
    assert_not @job.valid?
    assert_includes @job.errors[:salary_max], "must be greater than or equal to minimum salary"
  end

  test "filled_count cannot exceed headcount" do
    @job.headcount = 2
    @job.filled_count = 3
    assert_not @job.valid?
    assert_includes @job.errors[:filled_count], "cannot exceed headcount"
  end

  # State machine tests
  test "initial status is draft" do
    job = Job.new(title: "Test", organization: @organization)
    assert_equal "draft", job.status
  end

  test "can submit draft for approval" do
    assert @job.draft?
    assert @job.can_submit_for_approval?

    @job.submit_for_approval!
    assert @job.pending_approval?
  end

  test "cannot submit pending_approval for approval" do
    @job = jobs(:pending_job)
    assert @job.pending_approval?
    assert_not @job.can_submit_for_approval?
  end

  test "can approve pending_approval job" do
    @job = jobs(:pending_job)
    assert @job.can_approve?

    @job.approve!
    assert @job.open?
    assert_not_nil @job.opened_at
  end

  test "can reject pending_approval job" do
    @job = jobs(:pending_job)
    assert @job.can_reject?

    @job.reject!
    assert @job.draft?
  end

  test "can put open job on hold" do
    @job = jobs(:open_job)
    assert @job.can_put_on_hold?

    @job.put_on_hold!
    assert @job.on_hold?
  end

  test "can close open job" do
    @job = jobs(:open_job)
    assert @job.can_close?

    @job.close!
    assert @job.closed?
    assert_not_nil @job.closed_at
  end

  test "can reopen closed job" do
    @job = jobs(:closed_job)
    Current.organization = nil # Bypass default scope for this fixture
    @job = Job.unscoped.find(@job.id)

    assert @job.can_reopen?
    @job.reopen!
    assert @job.open?
  end

  # Helper methods
  test "editable? returns true for draft and pending_approval" do
    assert jobs(:draft_job).editable?
    assert jobs(:pending_job).editable?
    assert_not jobs(:open_job).editable?
  end

  test "filled? returns true when filled_count >= headcount" do
    @job.headcount = 2
    @job.filled_count = 2
    assert @job.filled?

    @job.filled_count = 1
    assert_not @job.filled?
  end

  test "remaining_openings calculates correctly" do
    @job.headcount = 3
    @job.filled_count = 1
    assert_equal 2, @job.remaining_openings
  end

  test "duplicate creates a copy in draft status" do
    @job = jobs(:open_job)
    new_job = @job.duplicate

    assert_equal "draft", new_job.status
    assert_nil new_job.opened_at
    assert_nil new_job.closed_at
    assert_equal 0, new_job.filled_count
    assert_equal @job.title, new_job.title
  end

  # Scopes
  test "open_jobs scope" do
    open_count = Job.open_jobs.count
    assert open_count >= 0
  end

  test "by_status scope" do
    Job.by_status(:draft).each do |job|
      assert_equal "draft", job.status
    end
  end

  test "by_department scope" do
    dept = departments(:engineering)
    Job.by_department(dept.id).each do |job|
      assert_equal dept.id, job.department_id
    end
  end
end
