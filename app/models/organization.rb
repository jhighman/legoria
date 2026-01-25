# frozen_string_literal: true

class Organization < ApplicationRecord
  include Discardable

  # Associations - all tenant-scoped models
  has_many :users, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :departments, dependent: :destroy
  has_many :stages, dependent: :destroy
  has_many :rejection_reasons, dependent: :destroy
  has_many :competencies, dependent: :destroy
  has_many :custom_fields, dependent: :destroy
  has_many :jobs, dependent: :destroy
  has_many :job_templates, dependent: :destroy
  has_many :candidates, dependent: :destroy
  has_many :applications, dependent: :destroy
  has_many :agencies, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :talent_pools, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  has_many :organization_settings, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :sso_configs, dependent: :destroy
  has_many :lookup_types, dependent: :destroy
  has_one :branding, class_name: "OrganizationBranding", dependent: :destroy

  # Phase 4: Offers & Compliance
  has_many :offer_templates, dependent: :destroy
  has_many :offers, dependent: :destroy
  has_many :eeoc_responses, dependent: :destroy
  has_many :gdpr_consents, dependent: :destroy
  has_many :data_retention_policies, dependent: :destroy
  has_many :deletion_requests, dependent: :destroy
  has_many :adverse_actions, dependent: :destroy

  # Phase 5: Intelligence
  has_many :parsed_resumes, dependent: :destroy
  has_many :candidate_skills, dependent: :destroy
  has_many :saved_searches, dependent: :destroy
  has_many :automation_rules, dependent: :destroy
  has_many :automation_logs, dependent: :destroy
  has_many :candidate_scores, dependent: :destroy
  has_many :job_requirements, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :subdomain, presence: true,
                        uniqueness: { case_sensitive: false },
                        length: { minimum: 3, maximum: 63 },
                        format: {
                          with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/,
                          message: "must contain only lowercase letters, numbers, and hyphens"
                        }
  validates :domain, uniqueness: { case_sensitive: false, allow_nil: true }
  validates :timezone, presence: true
  validates :default_currency, presence: true
  validates :default_locale, presence: true
  validates :plan, presence: true, inclusion: { in: %w[trial starter professional enterprise] }

  # Normalize subdomain before validation
  before_validation :normalize_subdomain

  # Create default data after organization creation
  after_create :create_default_roles
  after_create :create_default_stages
  after_create :create_default_rejection_reasons
  after_create :create_default_lookup_types

  # Settings accessors
  def setting(key)
    settings&.dig(key.to_s)
  end

  def set_setting(key, value)
    self.settings ||= {}
    self.settings[key.to_s] = value
  end

  # Feature flags
  def feature_enabled?(feature)
    settings&.dig("features", feature.to_s) == true
  end

  def enable_feature(feature)
    self.settings ||= {}
    self.settings["features"] ||= {}
    self.settings["features"][feature.to_s] = true
  end

  def disable_feature(feature)
    return unless settings&.dig("features")

    self.settings["features"][feature.to_s] = false
  end

  # Trial management
  def trial?
    plan == "trial"
  end

  def trial_expired?
    trial? && trial_ends_at.present? && trial_ends_at < Time.current
  end

  def trial_days_remaining
    return nil unless trial? && trial_ends_at.present?

    [(trial_ends_at.to_date - Date.current).to_i, 0].max
  end

  # Hostname helpers
  def hostname
    domain.presence || "#{subdomain}#{PlatformBrand.careers_subdomain_suffix}"
  end

  def full_url
    "https://#{hostname}"
  end

  private

  def normalize_subdomain
    self.subdomain = subdomain&.downcase&.strip
  end

  def create_default_roles
    [
      { name: "admin", description: "Full system access", system_role: true },
      { name: "recruiter", description: "Full recruiting access", system_role: true },
      { name: "hiring_manager", description: "Job and candidate management", system_role: true },
      { name: "interviewer", description: "Interview and feedback access", system_role: true }
    ].each do |role_attrs|
      roles.create!(role_attrs)
    end
  end

  def create_default_stages
    [
      { name: "Applied", stage_type: "applied", position: 0, is_default: true, color: "#6B7280" },
      { name: "Screening", stage_type: "screening", position: 1, is_default: true, color: "#3B82F6" },
      { name: "Interview", stage_type: "interview", position: 2, is_default: true, color: "#8B5CF6" },
      { name: "Offer", stage_type: "offer", position: 3, is_default: true, color: "#F59E0B" },
      { name: "Hired", stage_type: "hired", position: 4, is_default: true, is_terminal: true, color: "#10B981" },
      { name: "Rejected", stage_type: "rejected", position: 5, is_default: true, is_terminal: true, color: "#EF4444" }
    ].each do |stage_attrs|
      stages.create!(stage_attrs)
    end
  end

  def create_default_rejection_reasons
    [
      { name: "Does not meet minimum qualifications", category: "not_qualified", position: 0 },
      { name: "Insufficient experience", category: "not_qualified", position: 1 },
      { name: "Position filled", category: "timing", position: 2 },
      { name: "Position closed", category: "timing", position: 3 },
      { name: "Salary expectations too high", category: "compensation", position: 4 },
      { name: "Not a culture fit", category: "culture_fit", requires_notes: true, position: 5 },
      { name: "Candidate withdrew", category: "withdrew", position: 6 },
      { name: "Other", category: "other", requires_notes: true, position: 7 }
    ].each do |reason_attrs|
      rejection_reasons.create!(reason_attrs)
    end
  end

  def create_default_lookup_types
    lookup_definitions = {
      "employment_type" => {
        name: "Employment Type",
        description: "Types of employment arrangements",
        system_managed: true,
        values: [
          { code: "full_time", position: 0, is_default: true, translations: { "en" => { "name" => "Full-time" } } },
          { code: "part_time", position: 1, translations: { "en" => { "name" => "Part-time" } } },
          { code: "contract", position: 2, translations: { "en" => { "name" => "Contract" } } },
          { code: "intern", position: 3, translations: { "en" => { "name" => "Internship" } } },
          { code: "temporary", position: 4, translations: { "en" => { "name" => "Temporary" } } }
        ]
      },
      "location_type" => {
        name: "Location Type",
        description: "Work location arrangements",
        system_managed: true,
        values: [
          { code: "onsite", position: 0, translations: { "en" => { "name" => "On-site" } } },
          { code: "remote", position: 1, translations: { "en" => { "name" => "Remote" } } },
          { code: "hybrid", position: 2, is_default: true, translations: { "en" => { "name" => "Hybrid" } } }
        ]
      },
      "application_source" => {
        name: "Application Source",
        description: "How candidates found the job",
        system_managed: true,
        values: [
          { code: "career_site", position: 0, is_default: true, translations: { "en" => { "name" => "Career Site" } } },
          { code: "job_board", position: 1, translations: { "en" => { "name" => "Job Board" } } },
          { code: "referral", position: 2, translations: { "en" => { "name" => "Referral" } } },
          { code: "agency", position: 3, translations: { "en" => { "name" => "Agency" } } },
          { code: "direct", position: 4, translations: { "en" => { "name" => "Direct Application" } } },
          { code: "linkedin", position: 5, translations: { "en" => { "name" => "LinkedIn" } } },
          { code: "other", position: 6, translations: { "en" => { "name" => "Other" } } }
        ]
      },
      "note_visibility" => {
        name: "Note Visibility",
        description: "Who can see candidate notes",
        system_managed: true,
        values: [
          { code: "private", position: 0, translations: { "en" => { "name" => "Private", "description" => "Only visible to you" } } },
          { code: "team", position: 1, is_default: true, translations: { "en" => { "name" => "Team", "description" => "Visible to all recruiters" } } },
          { code: "hiring_team", position: 2, translations: { "en" => { "name" => "Hiring Team", "description" => "Visible to job hiring team" } } }
        ]
      }
    }

    lookup_definitions.each do |code, definition|
      lookup_type = lookup_types.create!(
        code: code,
        name: definition[:name],
        description: definition[:description],
        system_managed: definition[:system_managed] || false
      )

      definition[:values].each do |value_attrs|
        lookup_type.lookup_values.create!(value_attrs)
      end
    end
  end
end
