# frozen_string_literal: true

class I9Document < ApplicationRecord
  include OrganizationScoped

  # List types (USCIS Form I-9)
  LIST_TYPES = %w[list_a list_b list_c].freeze

  # List A Documents - Establish both identity AND employment authorization
  LIST_A_DOCUMENTS = {
    "us_passport" => "U.S. Passport",
    "us_passport_card" => "U.S. Passport Card",
    "permanent_resident_card" => "Permanent Resident Card (Green Card)",
    "foreign_passport_i94" => "Foreign Passport with I-94",
    "foreign_passport_i551" => "Foreign Passport with I-551 Stamp",
    "employment_authorization_document" => "Employment Authorization Document (EAD)",
    "foreign_passport_auto_extension" => "Foreign Passport with Auto Extension"
  }.freeze

  # List B Documents - Establish identity only
  LIST_B_DOCUMENTS = {
    "drivers_license" => "Driver's License",
    "state_id_card" => "State ID Card",
    "school_id_photo" => "School ID with Photo",
    "voter_registration_card" => "Voter Registration Card",
    "us_military_card" => "U.S. Military Card",
    "military_dependent_id" => "Military Dependent's ID Card",
    "uscg_merchant_mariner" => "USCG Merchant Mariner Document",
    "native_american_tribal_document" => "Native American Tribal Document"
  }.freeze

  # List C Documents - Establish employment authorization only
  LIST_C_DOCUMENTS = {
    "social_security_card" => "Social Security Card (Unrestricted)",
    "birth_certificate" => "Birth Certificate",
    "birth_certificate_abroad" => "Certification of Birth Abroad (FS-545)",
    "birth_report_abroad" => "Certification of Report of Birth (DS-1350)",
    "native_american_document" => "Native American Tribal Document",
    "us_citizen_id_card" => "U.S. Citizen ID Card (I-197)",
    "resident_citizen_id_card" => "ID Card for Resident Citizen (I-179)",
    "employment_authorization_dhs" => "Employment Authorization Document (DHS)"
  }.freeze

  # Associations
  belongs_to :i9_verification
  belongs_to :verified_by, class_name: "User", optional: true

  # File attachment
  has_one_attached :file

  # Validations
  validates :list_type, presence: true, inclusion: { in: LIST_TYPES }
  validates :document_type, presence: true

  validate :document_type_valid_for_list
  validate :file_attached, unless: :skip_file_validation?
  validate :file_size_acceptable
  validate :file_type_acceptable

  attr_accessor :skip_file_validation

  def skip_file_validation?
    skip_file_validation || Rails.env.test?
  end

  # Callbacks
  before_save :set_document_title

  # Scopes
  scope :list_a, -> { where(list_type: "list_a") }
  scope :list_b, -> { where(list_type: "list_b") }
  scope :list_c, -> { where(list_type: "list_c") }
  scope :verified_docs, -> { where(verified: true) }
  scope :unverified, -> { where(verified: false) }
  scope :expired, -> { where("expiration_date < ?", Date.current) }
  scope :valid_docs, -> { where("expiration_date IS NULL OR expiration_date >= ?", Date.current) }

  # Verification
  def verify!(user, notes: nil)
    update_columns(
      verified: true,
      verified_by_id: user.id,
      verified_at: Time.current,
      verification_notes: notes
    )
  end

  def unverify!
    update_columns(
      verified: false,
      verified_by_id: nil,
      verified_at: nil,
      verification_notes: nil
    )
  end

  # Status helpers
  def verified?
    verified
  end

  def expired?
    expiration_date.present? && expiration_date < Date.current
  end

  def expires_soon?(days = 30)
    return false unless expiration_date

    expiration_date <= days.days.from_now.to_date && expiration_date > Date.current
  end

  def valid_document?
    verified? && !expired?
  end

  # List type helpers
  def list_a?
    list_type == "list_a"
  end

  def list_b?
    list_type == "list_b"
  end

  def list_c?
    list_type == "list_c"
  end

  # Display helpers
  def list_type_label
    case list_type
    when "list_a" then "List A (Identity & Employment)"
    when "list_b" then "List B (Identity Only)"
    when "list_c" then "List C (Employment Only)"
    else list_type&.titleize
    end
  end

  def document_type_label
    documents_for_list[document_type] || document_type&.titleize&.gsub("_", " ")
  end

  def status_label
    return "Expired" if expired?
    return "Verified" if verified?

    "Pending Verification"
  end

  def status_color
    return "red" if expired?
    return "green" if verified?

    "yellow"
  end

  # Class methods
  def self.documents_for_list_type(list_type)
    case list_type
    when "list_a" then LIST_A_DOCUMENTS
    when "list_b" then LIST_B_DOCUMENTS
    when "list_c" then LIST_C_DOCUMENTS
    else {}
    end
  end

  def self.all_document_types
    LIST_A_DOCUMENTS.merge(LIST_B_DOCUMENTS).merge(LIST_C_DOCUMENTS)
  end

  private

  def documents_for_list
    self.class.documents_for_list_type(list_type)
  end

  def set_document_title
    self.document_title ||= document_type_label
  end

  def document_type_valid_for_list
    return if list_type.blank? || document_type.blank?

    valid_types = documents_for_list.keys

    unless valid_types.include?(document_type)
      errors.add(:document_type, "is not valid for #{list_type_label}")
    end
  end

  def file_attached
    return if file.attached?

    errors.add(:file, "must be attached")
  end

  def file_size_acceptable
    return unless file.attached?

    max_size = 10.megabytes
    if file.blob.byte_size > max_size
      errors.add(:file, "is too large (maximum is 10 MB)")
    end
  end

  def file_type_acceptable
    return unless file.attached?

    acceptable_types = %w[
      application/pdf
      image/jpeg
      image/png
      image/gif
    ]

    unless acceptable_types.include?(file.blob.content_type)
      errors.add(:file, "must be a PDF or image file")
    end
  end
end
