# frozen_string_literal: true

require "test_helper"

class QuestionBankTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @question = question_banks(:behavioral_question)
  end

  def teardown
    Current.organization = nil
  end

  test "valid question bank" do
    assert @question.valid?
  end

  test "requires question" do
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

  test "validates difficulty inclusion" do
    @question.difficulty = "invalid"
    assert_not @question.valid?
    assert_includes @question.errors[:difficulty], "is not included in the list"
  end

  test "allows blank difficulty" do
    @question.difficulty = nil
    assert @question.valid?
  end

  # Type helpers
  test "behavioral? returns true for behavioral questions" do
    assert @question.behavioral?
    assert_not question_banks(:technical_question).behavioral?
  end

  test "technical? returns true for technical questions" do
    assert question_banks(:technical_question).technical?
    assert_not @question.technical?
  end

  # Usage tracking
  test "record_usage! increments usage count" do
    initial_count = @question.usage_count
    @question.record_usage!
    assert_equal initial_count + 1, @question.reload.usage_count
  end

  # Tags management
  test "tags_array returns array of tags" do
    assert_equal %w[teamwork conflict leadership], @question.tags_array
  end

  test "tags_array= sets tags from array" do
    @question.tags_array = %w[new tag list]
    assert_equal "new,tag,list", @question.tags
  end

  test "add_tag adds a new tag" do
    @question.add_tag("newtag")
    assert_includes @question.tags_array, "newtag"
  end

  test "remove_tag removes a tag" do
    @question.remove_tag("teamwork")
    assert_not_includes @question.tags_array, "teamwork"
  end

  test "has_tag? checks if tag exists" do
    assert @question.has_tag?("teamwork")
    assert_not @question.has_tag?("nonexistent")
  end

  # Activation helpers
  test "activate! sets active to true" do
    inactive = question_banks(:inactive_question)
    inactive.activate!
    assert inactive.reload.active?
  end

  test "deactivate! sets active to false" do
    @question.deactivate!
    assert_not @question.reload.active?
  end

  # Scopes
  test "active scope returns only active questions" do
    active = QuestionBank.active
    active.each { |q| assert q.active? }
  end

  test "by_type scope filters by question type" do
    behavioral = QuestionBank.by_type("behavioral")
    behavioral.each { |q| assert_equal "behavioral", q.question_type }
  end

  test "by_difficulty scope filters by difficulty" do
    medium = QuestionBank.by_difficulty("medium")
    medium.each { |q| assert_equal "medium", q.difficulty }
  end
end
