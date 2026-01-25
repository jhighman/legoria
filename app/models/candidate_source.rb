# frozen_string_literal: true

class CandidateSource < ApplicationRecord
  # Fallback source types
  SOURCE_TYPES = %w[career_site job_board referral agency direct linkedin other].freeze

  # Associations
  belongs_to :candidate
  belongs_to :source_job, class_name: "Job", optional: true

  # Validations
  validates :source_type, presence: true
  validate :source_type_in_lookup

  # Scopes
  scope :by_type, ->(type) { where(source_type: type) }

  # Helpers
  def source_label
    LookupService.translate("application_source", source_type, organization: organization)
  end

  def organization
    candidate&.organization
  end

  private

  def source_type_in_lookup
    return if source_type.blank?

    valid_types = if organization
                    LookupService.valid_codes("application_source", organization: organization)
                  else
                    SOURCE_TYPES
                  end

    return if valid_types.include?(source_type)

    errors.add(:source_type, "is not a valid source type")
  end
end
