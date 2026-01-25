# frozen_string_literal: true

class I9DeadlineReminderJob < ApplicationJob
  queue_as :default

  # Run daily to check for I-9 deadlines approaching and overdue
  def perform
    check_upcoming_deadlines
    check_overdue_verifications
  end

  private

  def check_upcoming_deadlines
    # Find I-9s with Section 2 deadline approaching (1 day warning)
    I9Verification.unscoped
      .where(status: %w[section1_complete pending_section2])
      .where(deadline_section2: Date.tomorrow)
      .find_each do |verification|
        Current.organization = verification.organization

        I9NotificationJob.perform_later(
          verification.application_id,
          "section2_reminder"
        )
      ensure
        Current.reset
      end
  end

  def check_overdue_verifications
    # Find overdue I-9s for escalation and audit logging
    I9Verification.unscoped
      .where(status: %w[section1_complete pending_section2])
      .where("deadline_section2 < ?", Date.current)
      .find_each do |verification|
        Current.organization = verification.organization

        # Only log if not already marked late
        next if verification.late_completion?

        # Log compliance issue
        AuditLog.log(
          action: "i9.section2_overdue",
          auditable: verification,
          metadata: {
            i9_verification_id: verification.id,
            candidate_name: verification.candidate&.full_name,
            deadline: verification.deadline_section2&.iso8601,
            days_overdue: (Date.current - verification.deadline_section2).to_i
          }
        )

        # Mark as late for tracking (without completing)
        verification.update_columns(
          late_completion: true,
          late_completion_reason: "Section 2 deadline passed without completion"
        )
      ensure
        Current.reset
      end
  end
end
