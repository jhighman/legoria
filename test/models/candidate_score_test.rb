# frozen_string_literal: true

require "test_helper"

class CandidateScoreTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:acme)
    @application = applications(:active_application)
    Current.organization = @organization
    Current.user = users(:admin)
  end

  teardown do
    Current.reset
  end

  # Validations
  test "requires overall_score" do
    score = CandidateScore.new(
      organization: @organization,
      application: applications(:new_application),
      job: jobs(:draft_job),
      candidate: candidates(:jane_smith),
      scored_at: Time.current
    )
    assert_not score.valid?
    assert_includes score.errors[:overall_score], "can't be blank"
  end

  test "validates overall_score range" do
    score = candidate_scores(:john_active_score)

    score.overall_score = -1
    assert_not score.valid?

    score.overall_score = 101
    assert_not score.valid?

    score.overall_score = 50
    assert score.valid?
  end

  test "requires scored_at" do
    score = CandidateScore.new(
      organization: @organization,
      application: applications(:new_application),
      job: jobs(:draft_job),
      candidate: candidates(:jane_smith),
      overall_score: 75
    )
    assert_not score.valid?
    assert_includes score.errors[:scored_at], "can't be blank"
  end

  test "validates application uniqueness" do
    existing = candidate_scores(:john_active_score)
    duplicate = CandidateScore.new(
      organization: @organization,
      application: existing.application,
      job: existing.job,
      candidate: existing.candidate,
      overall_score: 80,
      scored_at: Time.current
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:application_id], "has already been taken"
  end

  # Score category
  test "score_category returns high for 80+" do
    score = candidate_scores(:john_active_score)
    assert_equal "high", score.score_category
  end

  test "score_category returns medium for 50-79" do
    score = candidate_scores(:jane_score)
    assert_equal "medium", score.score_category
  end

  test "score_category returns low for below 50" do
    score = candidate_scores(:jane_score)
    score.overall_score = 40
    assert_equal "low", score.score_category
  end

  # Component scores
  test "component_score returns specific component" do
    score = candidate_scores(:john_active_score)
    assert_equal 90, score.component_score(:skills_match)
    assert_equal 85, score.component_score("experience_match")
  end

  test "matched_skills returns matched skills array" do
    score = candidate_scores(:john_active_score)
    assert_includes score.matched_skills, "Ruby"
    assert_includes score.matched_skills, "Rails"
  end

  test "missing_skills returns missing skills array" do
    score = candidate_scores(:john_active_score)
    assert_includes score.missing_skills, "Kubernetes"
  end

  test "bonus_skills returns bonus skills array" do
    score = candidate_scores(:john_active_score)
    assert_includes score.bonus_skills, "JavaScript"
  end

  # Override
  test "override changes score and sets manual_override" do
    score = candidate_scores(:jane_score)
    original_score = score.overall_score
    admin = users(:admin)

    score.override!(new_score: 95, overrider: admin, reason: "Exceptional interview")

    assert_equal 95, score.overall_score
    assert score.manual_override?
    assert_equal admin, score.overridden_by
    assert_equal original_score.to_s, score.score_explanation.dig("manual_override", "original_score").to_s
    assert_equal "Exceptional interview", score.score_explanation.dig("manual_override", "reason")
  end

  # Scopes
  test "high_scoring returns scores 80+" do
    assert_includes CandidateScore.high_scoring, candidate_scores(:john_active_score)
    assert_not_includes CandidateScore.high_scoring, candidate_scores(:jane_score)
  end

  test "medium_scoring returns scores 50-79" do
    assert_includes CandidateScore.medium_scoring, candidate_scores(:jane_score)
    assert_not_includes CandidateScore.medium_scoring, candidate_scores(:john_active_score)
  end

  test "overridden scope returns overridden scores" do
    assert_includes CandidateScore.overridden, candidate_scores(:overridden_score)
    assert_not_includes CandidateScore.overridden, candidate_scores(:john_active_score)
  end

  test "not_overridden scope returns non-overridden scores" do
    assert_includes CandidateScore.not_overridden, candidate_scores(:john_active_score)
    assert_not_includes CandidateScore.not_overridden, candidate_scores(:overridden_score)
  end
end
