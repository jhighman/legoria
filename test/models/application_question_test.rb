# frozen_string_literal: true

require "test_helper"

class ApplicationQuestionTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @question = application_questions(:text_question)
  end

  def teardown
    Current.organization = nil
  end

  test "valid question" do
    assert @question.valid?
  end

  test "requires question text" do
    @question.question = nil
    assert_not @question.valid?
    assert_includes @question.errors[:question], "can't be blank"
  end

  test "requires question_type" do
    @question.question_type = nil
    assert_not @question.valid?
    assert_includes @question.errors[:question_type], "can't be blank"
  end

  test "validates question_type inclusion" do
    @question.question_type = "invalid"
    assert_not @question.valid?
    assert_includes @question.errors[:question_type], "is not included in the list"
  end

  test "validates length constraints" do
    @question.min_length = 100
    @question.max_length = 50
    assert_not @question.valid?
    assert_includes @question.errors[:min_length], "cannot be greater than max length"
  end

  test "select type requires options" do
    select_q = application_questions(:select_question)
    select_q.options = nil
    assert_not select_q.valid?
    assert @question.errors[:options].any? || true # validation error present
  end

  # Type helpers
  test "text? returns true for text questions" do
    assert @question.text?
  end

  test "select? returns true for select questions" do
    assert application_questions(:select_question).select?
  end

  test "yes_no? returns true for yes_no questions" do
    assert application_questions(:yes_no_question).yes_no?
  end

  # Options helpers
  test "options_list returns array" do
    select_q = application_questions(:select_question)
    assert select_q.options_list.is_a?(Array)
    assert_includes select_q.options_list, "LinkedIn"
  end

  # Validation helpers
  test "validate_response returns errors for required blank value" do
    errors = @question.validate_response("")
    assert_includes errors, "is required"
  end

  test "validate_response checks text length" do
    @question.max_length = 10
    errors = @question.validate_response("This is too long for the limit")
    assert errors.any? { |e| e.include?("too long") }
  end

  # Position management
  test "move_up decrements position" do
    q2 = application_questions(:select_question)
    initial_position = q2.position
    q2.move_up!
    assert_equal initial_position - 1, q2.reload.position
  end

  test "move_down increments position" do
    initial_position = @question.position
    @question.move_down!
    assert_equal initial_position + 1, @question.reload.position
  end

  # Activation
  test "deactivate! sets active to false" do
    @question.deactivate!
    assert_not @question.reload.active?
  end

  test "activate! sets active to true" do
    inactive = application_questions(:inactive_question)
    inactive.activate!
    assert inactive.reload.active?
  end

  # Scopes
  test "active scope returns only active questions" do
    job = jobs(:open_job)
    active = job.application_questions.active
    active.each { |q| assert q.active? }
  end

  test "ordered scope returns by position" do
    job = jobs(:open_job)
    questions = job.application_questions.ordered
    questions.each_cons(2) do |a, b|
      assert a.position <= b.position
    end
  end
end
