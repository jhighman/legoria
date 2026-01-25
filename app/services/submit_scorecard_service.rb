# frozen_string_literal: true

class SubmitScorecardService < ApplicationService
  # Submit a completed scorecard
  #
  # @example
  #   result = SubmitScorecardService.call(
  #     scorecard: scorecard,
  #     submitted_by: current_user
  #   )

  option :scorecard
  option :submitted_by
  option :notify_team, default: -> { true }

  def call
    yield validate_scorecard
    yield validate_submitter
    yield validate_completion

    yield submit_scorecard
    yield notify_team_members if notify_team

    Success(scorecard)
  end

  private

  def validate_scorecard
    return Failure(:scorecard_not_found) if scorecard.nil?
    return Failure(:scorecard_already_submitted) if scorecard.submitted? || scorecard.locked?
    return Failure(:interview_not_completed) unless scorecard.interview.completed?

    Success(scorecard)
  end

  def validate_submitter
    return Failure(:not_authorized) if submitted_by.nil?
    return Failure(:not_scorecard_owner) if scorecard.interview_participant.user_id != submitted_by.id

    Success(submitted_by)
  end

  def validate_completion
    # Check recommendation
    if scorecard.overall_recommendation.blank?
      return Failure("Overall recommendation is required")
    end

    # Check summary
    if scorecard.summary.blank?
      return Failure("Summary is required")
    end

    # Check required template items
    if scorecard.scorecard_template.present?
      required_items = scorecard.scorecard_template.scorecard_template_items.required
      answered_ids = scorecard.scorecard_responses.pluck(:scorecard_template_item_id)

      missing = required_items.where.not(id: answered_ids)
      if missing.any?
        return Failure("Please complete all required fields: #{missing.pluck(:name).join(', ')}")
      end
    end

    Success(true)
  end

  def submit_scorecard
    if scorecard.submit
      Success(scorecard)
    else
      Failure(scorecard.errors.full_messages.join(", "))
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure(e.record.errors.full_messages.join(", "))
  end

  def notify_team_members
    # Notify hiring manager
    hiring_manager = scorecard.job.hiring_manager
    if hiring_manager.present?
      ScorecardMailer.submitted_notification(scorecard, hiring_manager).deliver_later
    end

    # Notify recruiter
    recruiter = scorecard.job.recruiter
    if recruiter.present? && recruiter.id != hiring_manager&.id
      ScorecardMailer.submitted_notification(scorecard, recruiter).deliver_later
    end

    Success(true)
  rescue StandardError => e
    Rails.logger.error("Failed to send scorecard notifications: #{e.message}")
    Success(true) # Don't fail submission for notification errors
  end
end
