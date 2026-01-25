# frozen_string_literal: true

require "test_helper"

class StageTransitionTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @transition = stage_transitions(:screening_transition)
  end

  def teardown
    Current.organization = nil
  end

  test "valid stage transition" do
    assert @transition.valid?
  end

  test "requires to_stage" do
    @transition.to_stage = nil
    assert_not @transition.valid?
    assert_includes @transition.errors[:to_stage_id], "can't be blank"
  end

  test "validates stages are different" do
    @transition.from_stage_id = @transition.to_stage_id
    assert_not @transition.valid?
    assert_includes @transition.errors[:to_stage_id], "must be different from the current stage"
  end

  test "allows nil from_stage for initial transitions" do
    initial = stage_transitions(:initial_transition)
    assert_nil initial.from_stage_id
    assert initial.valid?
  end

  test "cannot update existing transition" do
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      @transition.notes = "Changed notes"
      @transition.save!
    end
  end

  test "cannot destroy existing transition" do
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      @transition.destroy!
    end
  end

  test "from_stage_name returns stage name or default" do
    assert_equal "Applied", @transition.from_stage_name

    initial = stage_transitions(:initial_transition)
    assert_equal "New Application", initial.from_stage_name
  end

  test "to_stage_name returns stage name" do
    assert_equal "Phone Screen", @transition.to_stage_name
  end

  test "mover_name returns user name or System" do
    assert_equal users(:recruiter).full_name, @transition.mover_name

    @transition.moved_by = nil
    assert_equal "System", @transition.mover_name
  end

  test "description generates readable string" do
    assert_match(/Moved from Applied to Phone Screen/, @transition.description)
  end

  test "duration_formatted handles hours" do
    @transition.duration_hours = 12
    assert_equal "12 hours", @transition.duration_formatted
  end

  test "duration_formatted handles days" do
    @transition.duration_hours = 48
    assert_equal "2.0 days", @transition.duration_formatted
  end

  test "duration_formatted handles weeks" do
    @transition.duration_hours = 336 # 14 days
    assert_equal "2.0 weeks", @transition.duration_formatted
  end

  test "chronological scope orders by created_at asc" do
    transitions = StageTransition.chronological
    assert transitions.first.created_at <= transitions.last.created_at
  end

  test "recent scope orders by created_at desc" do
    transitions = StageTransition.recent
    assert transitions.first.created_at >= transitions.last.created_at
  end
end
