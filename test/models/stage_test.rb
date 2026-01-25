# frozen_string_literal: true

require "test_helper"

class StageTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @stage = stages(:applied)
  end

  def teardown
    Current.organization = nil
  end

  test "valid stage" do
    assert @stage.valid?
  end

  test "requires name" do
    @stage.name = nil
    assert_not @stage.valid?
    assert_includes @stage.errors[:name], "can't be blank"
  end

  test "requires stage_type" do
    @stage.stage_type = nil
    assert_not @stage.valid?
    assert_includes @stage.errors[:stage_type], "can't be blank"
  end

  test "stage_type must be valid" do
    @stage.stage_type = "invalid"
    assert_not @stage.valid?
    assert_includes @stage.errors[:stage_type], "is not included in the list"
  end

  test "valid stage types" do
    Stage::STAGE_TYPES.each do |type|
      @stage.stage_type = type
      assert @stage.valid?, "Stage should be valid with type: #{type}"
    end
  end

  test "requires position" do
    @stage.position = nil
    assert_not @stage.valid?
    assert_includes @stage.errors[:position], "can't be blank"
  end

  test "position must be non-negative" do
    @stage.position = -1
    assert_not @stage.valid?

    @stage.position = 0
    assert @stage.valid?
  end

  test "color format validation" do
    @stage.color = "invalid"
    assert_not @stage.valid?

    @stage.color = "#FF0000"
    assert @stage.valid?

    @stage.color = nil
    assert @stage.valid?
  end

  test "stage type predicate methods" do
    @stage.stage_type = "applied"
    assert @stage.applied?

    @stage.stage_type = "screening"
    assert @stage.screening?

    @stage.stage_type = "interview"
    assert @stage.interview?

    @stage.stage_type = "offer"
    assert @stage.offer?

    @stage.stage_type = "hired"
    assert @stage.hired?

    @stage.stage_type = "rejected"
    assert @stage.rejected?
  end

  test "terminal? returns is_terminal value" do
    @stage.is_terminal = true
    assert @stage.terminal?

    @stage.is_terminal = false
    assert_not @stage.terminal?
  end

  test "active? returns opposite of terminal" do
    @stage.is_terminal = true
    assert_not @stage.active?

    @stage.is_terminal = false
    assert @stage.active?
  end

  test "ordered scope" do
    stages = Stage.ordered
    positions = stages.pluck(:position)
    assert_equal positions.sort, positions
  end

  test "default_stages scope" do
    default = Stage.default_stages
    default.each do |stage|
      assert stage.is_default?
    end
  end

  test "terminal scope" do
    terminal = Stage.terminal
    terminal.each do |stage|
      assert stage.terminal?
    end
  end
end
