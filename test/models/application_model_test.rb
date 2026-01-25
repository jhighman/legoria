# frozen_string_literal: true

require "test_helper"

class ApplicationModelTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @application = applications(:active_application)
    @new_application = applications(:new_application)
  end

  def teardown
    Current.organization = nil
  end

  test "valid application" do
    assert @application.valid?
  end

  test "requires status" do
    @application.status = nil
    assert_not @application.valid?
  end

  test "validates status inclusion" do
    @application.status = "invalid"
    assert_not @application.valid?
    assert_includes @application.errors[:status], "is not included in the list"
  end

  test "requires source_type" do
    @application.source_type = nil
    assert_not @application.valid?
  end

  test "validates source_type inclusion" do
    @application.source_type = "invalid"
    assert_not @application.valid?
  end

  test "requires applied_at" do
    @application.applied_at = nil
    assert_not @application.valid?
  end

  test "validates rating range" do
    @application.rating = 6
    assert_not @application.valid?

    @application.rating = 0
    assert_not @application.valid?

    @application.rating = 3
    assert @application.valid?
  end

  # State machine tests
  test "initial status is new" do
    job = jobs(:open_job)
    candidate = candidates(:jane_smith)
    app = Application.new(
      organization: @organization,
      job: job,
      candidate: candidate,
      current_stage: stages(:applied),
      source_type: "direct",
      applied_at: Time.current
    )
    assert_equal "new", app.status
  end

  test "can advance to screening from new" do
    @new_application.advance_to_screening!
    assert_equal "screening", @new_application.status
  end

  test "can advance to interviewing" do
    @new_application.status = "screening"
    @new_application.save!
    @new_application.advance_to_interviewing!
    assert_equal "interviewing", @new_application.status
  end

  test "can reject from active status" do
    assert @new_application.can_reject?
    @new_application.reject!
    assert @new_application.rejected?
    assert_not_nil @new_application.rejected_at
  end

  test "cannot reject from terminal status" do
    rejected = applications(:rejected_application)
    assert_not rejected.can_reject?
  end

  test "can withdraw from active status" do
    assert @new_application.can_withdraw?
    @new_application.withdraw!
    assert @new_application.withdrawn?
    assert_not_nil @new_application.withdrawn_at
  end

  # Status helpers
  test "active? returns true for active statuses" do
    assert @application.active?

    rejected = applications(:rejected_application)
    assert_not rejected.active?
  end

  test "terminal? returns true for terminal statuses" do
    rejected = applications(:rejected_application)
    assert rejected.terminal?

    assert_not @application.terminal?
  end

  # Rating and starring
  test "rate! sets rating" do
    @application.rate!(5)
    assert_equal 5, @application.rating
  end

  test "star! sets starred to true" do
    @new_application.star!
    assert @new_application.starred?
  end

  test "unstar! sets starred to false" do
    @application.unstar!
    assert_not @application.starred?
  end

  test "toggle_star! toggles starred status" do
    original = @application.starred?
    @application.toggle_star!
    assert_not_equal original, @application.starred?
  end

  # Scopes
  test "active scope returns only active applications" do
    Application.active.each do |app|
      assert app.active?
    end
  end

  test "by_status scope filters by status" do
    Application.by_status("new").each do |app|
      assert_equal "new", app.status
    end
  end

  test "starred scope returns only starred applications" do
    Application.starred.each do |app|
      assert app.starred?
    end
  end

  # Display helpers
  test "status_label returns titleized status" do
    assert_equal "Screening", @application.status_label
  end

  test "days_since_applied calculates correctly" do
    @application.applied_at = 5.days.ago
    assert_equal 5, @application.days_since_applied
  end
end
