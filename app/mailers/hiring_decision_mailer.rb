# frozen_string_literal: true

class HiringDecisionMailer < ApplicationMailer
  # Email to approvers requesting approval
  def approval_requested(hiring_decision, approver)
    @hiring_decision = hiring_decision
    @approver = approver
    @candidate = hiring_decision.candidate
    @job = hiring_decision.job
    @decider = hiring_decision.decided_by

    mail(
      to: approver.email,
      subject: "Hiring Decision Approval Required - #{@candidate.full_name} for #{@job.title}"
    )
  end

  # Email when decision is approved
  def decision_approved(hiring_decision)
    @hiring_decision = hiring_decision
    @candidate = hiring_decision.candidate
    @job = hiring_decision.job
    @decider = hiring_decision.decided_by
    @approver = hiring_decision.approved_by

    mail(
      to: @decider.email,
      subject: "Hiring Decision Approved - #{@candidate.full_name} for #{@job.title}"
    )
  end

  # Email when decision is rejected
  def decision_rejected(hiring_decision, reason = nil)
    @hiring_decision = hiring_decision
    @candidate = hiring_decision.candidate
    @job = hiring_decision.job
    @decider = hiring_decision.decided_by
    @reason = reason

    mail(
      to: @decider.email,
      subject: "Hiring Decision Requires Revision - #{@candidate.full_name} for #{@job.title}"
    )
  end
end
