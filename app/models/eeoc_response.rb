# frozen_string_literal: true

class EeocResponse < ApplicationRecord
  include OrganizationScoped

  # Valid values for each field
  GENDERS = %w[male female non_binary prefer_not_to_say].freeze
  RACE_ETHNICITIES = %w[
    hispanic_latino
    white
    black
    asian
    native_american
    pacific_islander
    two_or_more
    prefer_not_to_say
  ].freeze
  VETERAN_STATUSES = %w[protected_veteran not_veteran prefer_not_to_say].freeze
  DISABILITY_STATUSES = %w[yes no prefer_not_to_say].freeze
  COLLECTION_CONTEXTS = %w[application post_apply_email offer_stage].freeze

  # Associations
  belongs_to :application

  # Delegations
  delegate :candidate, :job, to: :application

  # Validations
  validates :application_id, uniqueness: true
  validates :gender, inclusion: { in: GENDERS }, allow_nil: true
  validates :race_ethnicity, inclusion: { in: RACE_ETHNICITIES }, allow_nil: true
  validates :veteran_status, inclusion: { in: VETERAN_STATUSES }, allow_nil: true
  validates :disability_status, inclusion: { in: DISABILITY_STATUSES }, allow_nil: true
  validates :collection_context, inclusion: { in: COLLECTION_CONTEXTS }, allow_nil: true

  validate :consent_required_for_data

  # Scopes
  scope :with_consent, -> { where(consent_given: true) }
  scope :without_consent, -> { where(consent_given: false) }
  scope :by_context, ->(context) { where(collection_context: context) if context.present? }

  # Check if any data was provided
  def any_data_provided?
    gender.present? || race_ethnicity.present? || veteran_status.present? || disability_status.present?
  end

  def all_declined?
    gender == "prefer_not_to_say" &&
      race_ethnicity == "prefer_not_to_say" &&
      veteran_status == "prefer_not_to_say" &&
      disability_status == "prefer_not_to_say"
  end

  # Consent management
  def record_consent!(ip_address: nil)
    update!(
      consent_given: true,
      consent_timestamp: Time.current,
      consent_ip_address: ip_address
    )
  end

  # Display helpers
  def gender_label
    return nil unless gender

    gender.titleize.gsub("_", " ")
  end

  def race_ethnicity_label
    return nil unless race_ethnicity

    case race_ethnicity
    when "hispanic_latino" then "Hispanic or Latino"
    when "white" then "White"
    when "black" then "Black or African American"
    when "asian" then "Asian"
    when "native_american" then "American Indian or Alaska Native"
    when "pacific_islander" then "Native Hawaiian or Other Pacific Islander"
    when "two_or_more" then "Two or More Races"
    when "prefer_not_to_say" then "Prefer not to say"
    else race_ethnicity.titleize
    end
  end

  def veteran_status_label
    return nil unless veteran_status

    case veteran_status
    when "protected_veteran" then "Protected Veteran"
    when "not_veteran" then "Not a Veteran"
    when "prefer_not_to_say" then "Prefer not to say"
    else veteran_status.titleize
    end
  end

  def disability_status_label
    return nil unless disability_status

    case disability_status
    when "yes" then "Yes, I have a disability"
    when "no" then "No, I do not have a disability"
    when "prefer_not_to_say" then "Prefer not to say"
    else disability_status.titleize
    end
  end

  def collection_context_label
    return nil unless collection_context

    case collection_context
    when "application" then "During Application"
    when "post_apply_email" then "Post-Application Email"
    when "offer_stage" then "Offer Stage"
    else collection_context.titleize
    end
  end

  private

  def consent_required_for_data
    return unless any_data_provided? && !consent_given?

    errors.add(:consent_given, "must be provided before collecting EEOC data")
  end
end
