# frozen_string_literal: true

require "test_helper"

class SubmitScorecardServiceTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @scorecard = scorecards(:draft_scorecard)
    @user = @scorecard.interview_participant.user
  end

  def teardown
    Current.organization = nil
  end

  test "submits scorecard successfully when complete" do
    # Ensure interview is completed
    @scorecard.interview.update_column(:status, "completed")
    @scorecard.interview.update_column(:completed_at, 1.day.ago)

    # Fill required fields
    @scorecard.overall_recommendation = "hire"
    @scorecard.summary = "Great candidate with strong skills"
    @scorecard.save!

    # Create responses for required template items
    create_required_responses(@scorecard)

    result = SubmitScorecardService.call(
      scorecard: @scorecard,
      submitted_by: @user,
      notify_team: false
    )

    assert result.success?
    @scorecard.reload
    assert @scorecard.submitted?
    assert @scorecard.visible_to_team?
  end

  test "fails if scorecard is nil" do
    result = SubmitScorecardService.call(
      scorecard: nil,
      submitted_by: @user,
      notify_team: false
    )

    assert result.failure?
    assert_equal :scorecard_not_found, result.failure
  end

  test "fails if scorecard already submitted" do
    submitted = scorecards(:submitted_scorecard)

    result = SubmitScorecardService.call(
      scorecard: submitted,
      submitted_by: submitted.interview_participant.user,
      notify_team: false
    )

    assert result.failure?
    assert_equal :scorecard_already_submitted, result.failure
  end

  test "fails if user is not scorecard owner" do
    # draft_scorecard is owned by completed_interviewer, whose user is recruiter
    # So we use a different user (hiring_manager) to test ownership check
    other_user = users(:hiring_manager)

    result = SubmitScorecardService.call(
      scorecard: @scorecard,
      submitted_by: other_user,
      notify_team: false
    )

    assert result.failure?
    assert_equal :not_scorecard_owner, result.failure
  end

  test "fails if interview not completed" do
    @scorecard.interview.update_column(:status, "scheduled")

    result = SubmitScorecardService.call(
      scorecard: @scorecard,
      submitted_by: @user,
      notify_team: false
    )

    assert result.failure?
    assert_equal :interview_not_completed, result.failure
  end

  test "fails if recommendation is missing" do
    @scorecard.interview.update_column(:status, "completed")
    @scorecard.overall_recommendation = nil
    @scorecard.summary = "Some summary"
    @scorecard.save(validate: false)

    result = SubmitScorecardService.call(
      scorecard: @scorecard,
      submitted_by: @user,
      notify_team: false
    )

    assert result.failure?
    assert_includes result.failure, "recommendation"
  end

  test "fails if summary is missing" do
    @scorecard.interview.update_column(:status, "completed")
    @scorecard.overall_recommendation = "hire"
    @scorecard.summary = nil
    @scorecard.save(validate: false)

    result = SubmitScorecardService.call(
      scorecard: @scorecard,
      submitted_by: @user,
      notify_team: false
    )

    assert result.failure?
    assert_includes result.failure, "Summary"
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
