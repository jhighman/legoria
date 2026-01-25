# frozen_string_literal: true

class GdprConsent < ApplicationRecord
  include OrganizationScoped

  # Consent types
  CONSENT_TYPES = %w[data_processing marketing third_party_sharing background_check].freeze
  COLLECTION_METHODS = %w[application_form email_link portal verbal].freeze

  # Associations
  belongs_to :candidate

  # Validations
  validates :consent_type, presence: true, inclusion: { in: CONSENT_TYPES }
  validates :collection_method, inclusion: { in: COLLECTION_METHODS }, allow_nil: true

  # Scopes
  scope :granted, -> { where(granted: true) }
  scope :withdrawn, -> { where(granted: false).where.not(withdrawn_at: nil) }
  scope :active, -> { granted.where(withdrawn_at: nil) }
  scope :by_type, ->(type) { where(consent_type: type) if type.present? }
  scope :recent, -> { order(created_at: :desc) }

  # Type helpers
  def data_processing?
    consent_type == "data_processing"
  end

  def marketing?
    consent_type == "marketing"
  end

  def third_party_sharing?
    consent_type == "third_party_sharing"
  end

  def background_check?
    consent_type == "background_check"
  end

  # Status helpers
  def active?
    granted? && withdrawn_at.nil?
  end

  def withdrawn?
    withdrawn_at.present?
  end

  # Actions
  def grant!(ip_address: nil, user_agent: nil, method: nil)
    update!(
      granted: true,
      granted_at: Time.current,
      withdrawn_at: nil,
      ip_address: ip_address,
      user_agent: user_agent,
      collection_method: method
    )
  end

  def withdraw!
    update!(
      granted: false,
      withdrawn_at: Time.current
    )
  end

  # Display helpers
  def consent_type_label
    case consent_type
    when "data_processing" then "Data Processing"
    when "marketing" then "Marketing Communications"
    when "third_party_sharing" then "Third Party Sharing"
    when "background_check" then "Background Check"
    else consent_type.titleize
    end
  end

  def status_label
    if active?
      "Active"
    elsif withdrawn?
      "Withdrawn"
    else
      "Not Granted"
    end
  end

  def status_color
    if active?
      "green"
    elsif withdrawn?
      "red"
    else
      "gray"
    end
  end

  # Class methods for checking consent
  class << self
    def has_active_consent?(candidate, consent_type)
      active.where(candidate: candidate, consent_type: consent_type).exists?
    end

    def get_active_consent(candidate, consent_type)
      active.find_by(candidate: candidate, consent_type: consent_type)
    end

    def required_consent_types
      %w[data_processing]
    end

    def optional_consent_types
      %w[marketing third_party_sharing background_check]
    end
  end
end
