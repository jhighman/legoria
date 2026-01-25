# frozen_string_literal: true

# Phase 5: Parsed resume data from AI/ML parsing
class ParsedResume < ApplicationRecord
  include OrganizationScoped

  belongs_to :candidate
  belongs_to :resume, optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true

  # Statuses
  STATUSES = %w[pending processing completed failed].freeze

  # Education levels
  EDUCATION_LEVELS = %w[high_school associate bachelor master doctorate].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :highest_education_level, inclusion: { in: EDUCATION_LEVELS }, allow_nil: true

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :processing, -> { where(status: "processing") }
  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }
  scope :reviewed, -> { where(reviewed: true) }
  scope :unreviewed, -> { where(reviewed: false) }
  scope :recent, -> { order(created_at: :desc) }

  # Start processing
  def start_processing!
    update!(status: "processing")
  end

  # Mark as completed with parsed data
  def complete!(parsed_data:)
    update!(
      status: "completed",
      parsed_name: parsed_data["name"],
      parsed_email: parsed_data["email"],
      parsed_phone: parsed_data["phone"],
      parsed_location: parsed_data["location"],
      summary: parsed_data["summary"],
      work_experience: parsed_data["experience"],
      education: parsed_data["education"],
      skills: parsed_data["skills"],
      certifications: parsed_data["certifications"],
      languages: parsed_data["languages"],
      raw_response: parsed_data["raw_response"]
    )
  end

  # Mark as failed
  def fail!(message)
    update!(
      status: "failed",
      error_message: message
    )
  end

  # Mark as reviewed
  def mark_reviewed!(reviewer)
    update!(
      reviewed: true,
      reviewed_by: reviewer,
      reviewed_at: Time.current
    )
  end

  # Check if we can retry
  def can_retry?
    status == "failed"
  end

  # Helper methods for accessing parsed data
  def contact_info
    {
      "name" => parsed_name,
      "email" => parsed_email,
      "phone" => parsed_phone,
      "location" => parsed_location,
      "linkedin" => parsed_linkedin_url
    }
  end

  # Work experience
  def work_history
    work_experience || []
  end

  # Education history
  def education_history
    education || []
  end

  # Skills list
  def skills_list
    skills || []
  end

  # Certifications list
  def certifications_list
    certifications || []
  end

  # Years of experience from parsed data
  def total_years_experience
    return years_of_experience if years_of_experience.present?

    work_history.sum do |exp|
      start_date = exp["start_date"]
      end_date = exp["end_date"] || Time.current.to_date.to_s
      next 0 unless start_date

      ((Date.parse(end_date) - Date.parse(start_date)) / 365.25).round
    rescue StandardError
      0
    end
  end
end
