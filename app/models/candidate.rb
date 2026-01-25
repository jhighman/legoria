# frozen_string_literal: true

class Candidate < ApplicationRecord
  include OrganizationScoped
  include Discardable

  # PII encryption - only encrypt SSN (most sensitive)
  # Email and phone use existing plaintext columns from initial migration
  ENCRYPTION_KEY = Rails.application.credentials.secret_key_base[0..31]

  attr_encrypted :ssn, key: ENCRYPTION_KEY, encode: true, encode_iv: true, allow_empty_value: true

  # Associations
  belongs_to :referred_by, class_name: "User", optional: true
  belongs_to :agency, optional: true
  belongs_to :merged_into, class_name: "Candidate", optional: true

  has_many :applications, dependent: :destroy
  has_many :jobs, through: :applications
  has_many :resumes, dependent: :destroy
  has_many :candidate_notes, dependent: :destroy
  has_many :candidate_sources, dependent: :destroy
  has_many :candidate_tags, dependent: :destroy
  has_many :tags, through: :candidate_tags
  has_many :candidate_documents, dependent: :destroy
  has_one :account, class_name: "CandidateAccount", dependent: :destroy

  # Phase 4: Compliance
  has_many :gdpr_consents, dependent: :destroy
  has_many :deletion_requests, dependent: :destroy

  # Phase 5: Intelligence
  has_many :parsed_resumes, dependent: :destroy
  has_many :candidate_skills, dependent: :destroy
  has_many :talent_pool_members, dependent: :destroy
  has_many :talent_pools, through: :talent_pool_members
  has_many :automation_logs, dependent: :nullify

  # Phase 8: I-9 and Work Authorization
  has_many :i9_verifications, dependent: :destroy
  has_many :work_authorizations, dependent: :destroy

  # Validations
  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, presence: true, length: { maximum: 100 }
  validates :email, presence: true
  validates :linkedin_url, format: { with: /\Ahttps?:\/\/.+\z/, allow_blank: true }
  validates :portfolio_url, format: { with: /\Ahttps?:\/\/.+\z/, allow_blank: true }

  validate :email_unique_in_organization

  # Scopes
  scope :active_candidates, -> { kept }
  scope :merged, -> { where.not(merged_into_id: nil) }
  scope :unmerged, -> { where(merged_into_id: nil) }
  scope :with_applications, -> { joins(:applications).distinct }
  scope :without_applications, -> { left_joins(:applications).where(applications: { id: nil }) }
  scope :referred, -> { where.not(referred_by_id: nil) }
  scope :from_agency, -> { where.not(agency_id: nil) }

  scope :search, ->(query) {
    return all if query.blank?

    # Use LIKE for SQLite compatibility (case-insensitive in SQLite by default)
    where("first_name LIKE :q OR last_name LIKE :q OR location LIKE :q",
          q: "%#{sanitize_sql_like(query)}%")
  }

  # Name helpers
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
  end

  def display_name
    full_name.presence || email
  end

  # Status helpers
  def merged?
    merged_into_id.present?
  end

  def has_active_applications?
    applications.active.exists?
  end

  def current_applications
    applications.active.includes(:job, :current_stage)
  end

  # Resume helpers
  def primary_resume
    resumes.find_by(primary: true) || resumes.order(created_at: :desc).first
  end

  # Source tracking
  def source
    # Return the original source (first source record)
    candidate_sources.order(:created_at).first
  end

  def source_type
    source&.source_type
  end

  # Merge functionality
  def merge_into!(target_candidate)
    return false if target_candidate == self
    return false if merged?

    transaction do
      # Move applications to target
      applications.update_all(candidate_id: target_candidate.id)

      # Move resumes to target
      resumes.update_all(candidate_id: target_candidate.id)

      # Move notes to target
      candidate_notes.update_all(candidate_id: target_candidate.id)

      # Mark as merged
      update!(
        merged_into_id: target_candidate.id,
        merged_at: Time.current
      )
    end

    true
  end

  # Masking for display
  def masked_ssn
    return nil if ssn.blank?

    "***-**-#{ssn.last(4)}"
  end

  def masked_phone
    return nil if phone.blank?

    phone.gsub(/\d(?=.{4})/, "*")
  end

  private

  def email_unique_in_organization
    return if email.blank?

    # Check for duplicates within the organization using database query
    existing = Candidate.kept
                        .where(organization_id: organization_id)
                        .where("LOWER(email) = ?", email.downcase)
                        .where.not(id: id)

    errors.add(:email, "has already been taken") if existing.exists?
  end
end
