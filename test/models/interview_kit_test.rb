# frozen_string_literal: true

require "test_helper"

class InterviewKitTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @kit = interview_kits(:default_kit)
  end

  def teardown
    Current.organization = nil
  end

  test "valid interview kit" do
    assert @kit.valid?
  end

  test "requires name" do
    @kit.name = nil
    assert_not @kit.valid?
    assert_includes @kit.errors[:name], "can't be blank"
  end

  test "validates interview_type inclusion" do
    @kit.interview_type = "invalid"
    assert_not @kit.valid?
    assert_includes @kit.errors[:interview_type], "is not included in the list"
  end

  test "allows blank interview_type" do
    @kit.interview_type = nil
    assert @kit.valid?
  end

  # Question management
  test "add_question creates a new question" do
    question_bank = question_banks(:behavioral_question)
    initial_count = @kit.interview_kit_questions.count

    @kit.add_question(question_bank: question_bank, time_allocation: 15)

    assert_equal initial_count + 1, @kit.interview_kit_questions.count
  end

  test "total_questions returns correct count" do
    assert_equal 3, @kit.total_questions
  end

  test "total_time_allocation sums time allocations" do
    assert_equal 25, @kit.total_time_allocation
  end

  # Duplication
  test "duplicate creates a copy with new name" do
    new_kit = @kit.duplicate

    assert_not_equal @kit.id, new_kit.id
    assert_equal "#{@kit.name} (Copy)", new_kit.name
    assert_not new_kit.is_default?
    assert_equal @kit.interview_kit_questions.count, new_kit.interview_kit_questions.count
  end

  test "duplicate with custom name" do
    new_kit = @kit.duplicate(new_name: "Custom Copy")
    assert_equal "Custom Copy", new_kit.name
  end

  # Activation helpers
  test "activate! sets active to true" do
    inactive = interview_kits(:inactive_kit)
    inactive.activate!
    assert inactive.reload.active?
  end

  test "deactivate! sets active to false" do
    @kit.deactivate!
    assert_not @kit.reload.active?
  end

  test "set_as_default! sets this kit as default" do
    technical_kit = interview_kits(:technical_kit)
    technical_kit.set_as_default!

    assert technical_kit.reload.is_default?
    assert_not @kit.reload.is_default?
  end

  # Find for interview
  test "find_for_interview returns job-specific kit" do
    interview = interviews(:scheduled_interview)
    job_kit = interview_kits(:job_specific_kit)
    job_kit.update!(job_id: interview.job_id)

    found = InterviewKit.find_for_interview(interview)
    assert_equal job_kit.id, found.id
  end

  test "find_for_interview returns default kit when no specific match" do
    interview = interviews(:scheduled_interview)
    # Remove job-specific kit for this job
    InterviewKit.where(job_id: interview.job_id).update_all(job_id: nil)

    found = InterviewKit.find_for_interview(interview)
    assert found.is_default?
  end

  # Scopes
  test "active scope returns only active kits" do
    active = InterviewKit.active
    active.each { |k| assert k.active? }
  end

  test "defaults scope returns only default kits" do
    defaults = InterviewKit.defaults
    defaults.each { |k| assert k.is_default? }
  end
end
