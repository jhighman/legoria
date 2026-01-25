# frozen_string_literal: true

require "test_helper"

class ScorecardTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @scorecard = scorecards(:draft_scorecard)
    @submitted = scorecards(:submitted_scorecard)
  end

  def teardown
    Current.organization = nil
  end

  test "valid scorecard" do
    assert @scorecard.valid?
  end

  test "requires status" do
    @scorecard.status = nil
    assert_not @scorecard.valid?
    assert_includes @scorecard.errors[:status], "can't be blank"
  end

  test "validates status inclusion" do
    @scorecard.status = "invalid"
    assert_not @scorecard.valid?
    assert_includes @scorecard.errors[:status], "is not included in the list"
  end

  test "validates recommendation inclusion" do
    @scorecard.overall_recommendation = "invalid"
    assert_not @scorecard.valid?
    assert_includes @scorecard.errors[:overall_recommendation], "is not included in the list"
  end

  test "allows blank recommendation" do
    @scorecard.overall_recommendation = nil
    assert @scorecard.valid?
  end

  # State machine tests
  test "initial state is draft" do
    scorecard = Scorecard.new
    assert_equal "draft", scorecard.status
  end

  test "can submit draft scorecard" do
    # Ensure interview is completed
    @scorecard.interview.update_column(:status, "completed")
    @scorecard.interview.update_column(:completed_at, 1.day.ago)

    @scorecard.overall_recommendation = "hire"
    @scorecard.summary = "Good candidate"
    @scorecard.save!

    # Create responses for required template items
    create_required_responses(@scorecard)

    assert @scorecard.can_submit?
    @scorecard.submit
    assert @scorecard.submitted?
    assert_not_nil @scorecard.submitted_at
  end

  test "cannot submit already submitted scorecard" do
    assert_not @submitted.can_submit?
  end

  test "can lock submitted scorecard" do
    assert @submitted.can_lock_scorecard?
    @submitted.lock_scorecard
    assert @submitted.locked?
    assert_not_nil @submitted.locked_at
  end

  # Status helpers
  test "draft? returns true for draft scorecards" do
    assert @scorecard.draft?
    assert_not @submitted.draft?
  end

  test "submitted? returns true for submitted scorecards" do
    assert @submitted.submitted?
    assert_not @scorecard.submitted?
  end

  test "editable? returns true only for drafts" do
    assert @scorecard.editable?
    assert_not @submitted.editable?
  end

  # Recommendation helpers
  test "recommendation_label returns human-readable label" do
    assert_equal "Hire", @submitted.recommendation_label
  end

  test "recommendation_color returns appropriate color" do
    assert_equal "emerald", @submitted.recommendation_color
  end

  test "positive_recommendation? returns true for hire recommendations" do
    assert @submitted.positive_recommendation?

    @submitted.overall_recommendation = "strong_hire"
    assert @submitted.positive_recommendation?
  end

  test "negative_recommendation? returns true for no_hire recommendations" do
    @submitted.overall_recommendation = "no_hire"
    assert @submitted.negative_recommendation?

    @submitted.overall_recommendation = "strong_no_hire"
    assert @submitted.negative_recommendation?
  end

  # Response management
  test "response_for returns response for item" do
    item = scorecard_template_items(:communication_item)
    response = @submitted.response_for(item)
    assert_not_nil response
    assert_equal item.id, response.scorecard_template_item_id
  end

  test "completion_percentage calculates correctly" do
    percentage = @submitted.completion_percentage
    assert percentage >= 0
    assert percentage <= 100
  end

  # Display helpers
  test "interviewer_name returns participant user name" do
    assert_equal @submitted.interview_participant.user.full_name, @submitted.interviewer_name
  end

  test "status_color returns appropriate color" do
    assert_equal "yellow", @scorecard.status_color
    assert_equal "green", @submitted.status_color
  end

  # Scopes
  test "drafts scope returns only draft scorecards" do
    drafts = Scorecard.drafts
    drafts.each { |s| assert_equal "draft", s.status }
  end

  test "submitted scope returns only submitted scorecards" do
    submitted = Scorecard.submitted
    submitted.each { |s| assert_equal "submitted", s.status }
  end

  test "visible scope returns only visible scorecards" do
    visible = Scorecard.visible
    visible.each { |s| assert s.visible_to_team? }
  end

  private

  def create_required_responses(scorecard)
    return unless scorecard.scorecard_template

    scorecard.scorecard_template.scorecard_template_items.required.each do |item|
      response = scorecard.scorecard_responses.find_or_initialize_by(scorecard_template_item: item)

      case item.item_type
      when "rating"
        response.rating = 4
      when "yes_no"
        response.yes_no_value = true
      when "text"
        response.text_value = "Test response"
      when "select"
        response.select_value = "option_1"
      end

      response.save!
    end
  end
end
