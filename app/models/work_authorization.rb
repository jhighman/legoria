# frozen_string_literal: true

class WorkAuthorization < ApplicationRecord
  include OrganizationScoped
  include Auditable

  # Audit configuration
  audit_actions create: "work_authorization.created", update: "work_authorization.updated"

  # Authorization types
  AUTHORIZATION_TYPES = %w[
    citizen
    permanent_resident
    ead
    h1b
    opt
    cpt
    tn
    l1
    other
  ].freeze

  # Types that have indefinite authorization
  INDEFINITE_TYPES = %w[citizen permanent_resident].freeze

  # Associations
  belongs_to :candidate
  belongs_to :i9_verification, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :verified_by, class_name: "User", optional: true

  # Validations
  validates :authorization_type, presence: true, inclusion: { in: AUTHORIZATION_TYPES }
  validates :valid_from, presence: true
  validates :valid_until, presence: true, unless: :indefinite?

  validate :valid_until_after_valid_from

  # Callbacks
  before_validation :set_indefinite_flag

  # Scopes
  scope :active, -> { where("indefinite = ? OR valid_until >= ?", true, Date.current) }
  scope :expired, -> { where(indefinite: false).where("valid_until < ?", Date.current) }

  scope :expiring_soon, ->(days = 90) {
    where(indefinite: false)
      .where("valid_until <= ?", days.days.from_now.to_date)
      .where("valid_until > ?", Date.current)
  }

  scope :requiring_reverification, -> {
    where(reverification_required: true)
      .where("reverification_due_date <= ?", 30.days.from_now.to_date)
  }

  scope :by_type, ->(type) { where(authorization_type: type) if type.present? }

  # Status helpers
  def expired?
    return false if indefinite?

    valid_until < Date.current
  end

  def active?
    return true if indefinite?

    valid_until >= Date.current
  end

  def expires_within?(days)
    return false if indefinite?

    valid_until <= days.days.from_now.to_date && valid_until > Date.current
  end

  def days_until_expiration
    return nil if indefinite?

    (valid_until - Date.current).to_i
  end

  def needs_reverification?
    return false if indefinite?
    return true if reverification_required?

    # Auto-flag for reverification if expiring within 90 days
    expires_within?(90)
  end

  # Reminder helpers
  def should_send_reminder?(days_threshold = 90)
    return false if indefinite?
    return false if reverification_reminder_sent?

    expires_within?(days_threshold)
  end

  def mark_reminder_sent!
    update!(
      reverification_reminder_sent: true,
      reverification_reminder_sent_at: Time.current
    )
  end

  # Display helpers
  def authorization_type_label
    case authorization_type
    when "citizen" then "U.S. Citizen"
    when "permanent_resident" then "Permanent Resident (Green Card)"
    when "ead" then "Employment Authorization Document (EAD)"
    when "h1b" then "H-1B Visa"
    when "opt" then "OPT (Optional Practical Training)"
    when "cpt" then "CPT (Curricular Practical Training)"
    when "tn" then "TN Visa"
    when "l1" then "L-1 Visa"
    when "other" then "Other Work Authorization"
    else authorization_type&.upcase
    end
  end

  def status_label
    return "Indefinite" if indefinite?
    return "Expired" if expired?
    return "Expiring Soon" if expires_within?(90)

    "Active"
  end

  def status_color
    return "green" if indefinite?
    return "red" if expired?
    return "yellow" if expires_within?(30)
    return "orange" if expires_within?(90)

    "green"
  end

  def validity_period
    return "Indefinite" if indefinite?

    "#{valid_from.strftime('%b %d, %Y')} - #{valid_until.strftime('%b %d, %Y')}"
  end

  private

  def set_indefinite_flag
    self.indefinite = INDEFINITE_TYPES.include?(authorization_type) if authorization_type.present?

    if indefinite?
      self.valid_until = nil
      self.reverification_required = false
    end
  end

  def valid_until_after_valid_from
    return if indefinite? || valid_from.blank? || valid_until.blank?

    if valid_until <= valid_from
      errors.add(:valid_until, "must be after valid from date")
    end
  end
end
