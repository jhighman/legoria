# frozen_string_literal: true

require "test_helper"

class InterviewParticipantTest < ActiveSupport::TestCase
  def setup
    @organization = organizations(:acme)
    Current.organization = @organization
    @participant = interview_participants(:lead_participant)
  end

  def teardown
    Current.organization = nil
  end

  test "valid participant" do
    assert @participant.valid?
  end

  test "requires role" do
    @participant.role = nil
    assert_not @participant.valid?
    assert_includes @participant.errors[:role], "can't be blank"
  end

  test "requires valid role" do
    @participant.role = "invalid_role"
    assert_not @participant.valid?
    assert_includes @participant.errors[:role], "is not included in the list"
  end

  test "requires status" do
    @participant.status = nil
    assert_not @participant.valid?
    assert_includes @participant.errors[:status], "can't be blank"
  end

  test "requires valid status" do
    @participant.status = "invalid_status"
    assert_not @participant.valid?
    assert_includes @participant.errors[:status], "is not included in the list"
  end

  test "unique user per interview" do
    duplicate = InterviewParticipant.new(
      interview: @participant.interview,
      user: @participant.user,
      role: "interviewer"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "is already a participant"
  end

  # Role helpers
  test "lead? returns true for lead role" do
    assert @participant.lead?
    assert_not interview_participants(:interviewer_participant).lead?
  end

  test "interviewer? returns true for lead and interviewer roles" do
    assert @participant.interviewer?
    assert interview_participants(:interviewer_participant).interviewer?
    assert_not interview_participants(:shadow_participant).interviewer?
  end

  test "shadow? returns true for shadow role" do
    assert interview_participants(:shadow_participant).shadow?
    assert_not @participant.shadow?
  end

  test "requires_feedback? returns true for interviewers only" do
    assert @participant.requires_feedback?
    assert_not interview_participants(:shadow_participant).requires_feedback?
  end

  # Status helpers
  test "pending? returns true for pending status" do
    pending = interview_participants(:interviewer_participant)
    assert pending.pending?
    assert_not @participant.pending?
  end

  test "accepted? returns true for accepted status" do
    assert @participant.accepted?
  end

  test "declined? returns true for declined status" do
    @participant.status = "declined"
    assert @participant.declined?
  end

  # Response methods
  test "accept! updates status and responded_at" do
    pending = interview_participants(:interviewer_participant)
    assert_nil pending.responded_at
    pending.accept!
    assert pending.accepted?
    assert_not_nil pending.responded_at
  end

  test "decline! updates status and responded_at" do
    pending = interview_participants(:interviewer_participant)
    pending.decline!
    assert pending.declined?
    assert_not_nil pending.responded_at
  end

  test "mark_tentative! updates status and responded_at" do
    pending = interview_participants(:interviewer_participant)
    pending.mark_tentative!
    assert pending.tentative?
    assert_not_nil pending.responded_at
  end

  # Feedback methods
  test "submit_feedback! marks feedback as submitted" do
    assert_not @participant.feedback_submitted?
    @participant.submit_feedback!
    assert @participant.feedback_submitted?
    assert_not_nil @participant.feedback_submitted_at
  end

  test "feedback_overdue? returns false if not requires_feedback" do
    shadow = interview_participants(:shadow_participant)
    assert_not shadow.feedback_overdue?
  end

  test "feedback_overdue? returns false if already submitted" do
    completed_lead = interview_participants(:completed_lead)
    assert_not completed_lead.feedback_overdue?
  end

  # Display helpers
  test "role_label titleizes role" do
    assert_equal "Lead", @participant.role_label
    @participant.role = "note_taker"
    assert_equal "Note Taker", @participant.role_label
  end

  test "status_color returns appropriate color" do
    assert_equal "green", @participant.status_color # accepted
    pending = interview_participants(:interviewer_participant)
    assert_equal "yellow", pending.status_color # pending
  end

  # Scopes
  test "leads scope returns only lead participants" do
    leads = InterviewParticipant.leads
    leads.each { |p| assert_equal "lead", p.role }
  end

  test "interviewers scope returns lead and interviewer roles" do
    interviewers = InterviewParticipant.interviewers
    interviewers.each { |p| assert_includes %w[lead interviewer], p.role }
  end

  test "needs_feedback scope returns interviewers without feedback" do
    needing = InterviewParticipant.needs_feedback
    needing.each do |p|
      assert p.interviewer?
      assert_not p.feedback_submitted?
    end
  end
end
