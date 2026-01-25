# frozen_string_literal: true

class ProcessDeletionRequestService < ApplicationService
  option :deletion_request
  option :processed_by

  def call
    yield validate_request
    yield start_processing
    deleted_data = yield delete_candidate_data
    yield complete_request(deleted_data)
    Success(deletion_request)
  end

  private

  def validate_request
    unless deletion_request.identity_verified?
      return Failure(errors: ["Identity must be verified before processing"])
    end

    if deletion_request.legal_hold?
      return Failure(errors: ["Request is on legal hold"])
    end

    unless deletion_request.pending? || deletion_request.in_progress?
      return Failure(errors: ["Request has already been processed"])
    end

    Success()
  end

  def start_processing
    deletion_request.start_processing!(processed_by) if deletion_request.pending?
    Success()
  rescue StandardError => e
    Failure(errors: [e.message])
  end

  def delete_candidate_data
    candidate = deletion_request.candidate
    deleted_data = {}
    retained_data = {}

    # Check for active applications - these prevent full deletion
    if candidate.has_active_applications?
      retained_data[:reason] = "Active applications exist"
      retained_data[:application_ids] = candidate.applications.active.pluck(:id)
    end

    # Delete or anonymize data
    ApplicationRecord.transaction do
      # Anonymize personal data
      deleted_data[:personal_data] = anonymize_personal_data(candidate)

      # Delete documents
      deleted_data[:documents] = delete_documents(candidate)

      # Delete GDPR consents (record of deletion)
      deleted_data[:consent_count] = candidate.gdpr_consents.count

      # Withdraw all consents
      candidate.gdpr_consents.active.each(&:withdraw!)

      # Delete notes (unless there are active applications)
      unless candidate.has_active_applications?
        deleted_data[:notes_count] = candidate.candidate_notes.count
        candidate.candidate_notes.destroy_all
      end
    end

    Success({ deleted: deleted_data, retained: retained_data })
  rescue StandardError => e
    Failure(errors: ["Failed to delete data: #{e.message}"])
  end

  def complete_request(data)
    deletion_request.complete!(
      deleted_data: data[:deleted],
      retained_data: data[:retained].presence
    )
    Success()
  rescue StandardError => e
    Failure(errors: [e.message])
  end

  def anonymize_personal_data(candidate)
    original = {
      first_name: candidate.first_name,
      last_name: candidate.last_name,
      phone: candidate.phone,
      location: candidate.location,
      linkedin_url: candidate.linkedin_url,
      portfolio_url: candidate.portfolio_url
    }

    # Keep email for record but anonymize other PII
    candidate.update!(
      first_name: "Deleted",
      last_name: "User",
      phone: nil,
      location: nil,
      linkedin_url: nil,
      portfolio_url: nil,
      ssn: nil
    )

    original.keys
  end

  def delete_documents(candidate)
    count = candidate.candidate_documents.count
    candidate.candidate_documents.each do |doc|
      doc.file.purge if doc.file.attached?
    end
    candidate.candidate_documents.destroy_all
    count
  end
end
