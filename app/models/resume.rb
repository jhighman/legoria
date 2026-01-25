# frozen_string_literal: true

class Resume < ApplicationRecord
  # Associations
  belongs_to :candidate

  # Active Storage attachment for the actual file
  has_one_attached :file

  # Validations
  validates :filename, presence: true
  validates :content_type, presence: true
  validates :file_size, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 10.megabytes }
  validates :storage_key, presence: true, uniqueness: true

  validate :acceptable_file_type

  # Callbacks
  before_validation :set_file_attributes, if: -> { file.attached? && file.blob.present? }
  after_save :ensure_single_primary, if: :primary?

  # Scopes
  scope :primary_first, -> { order(primary: :desc, created_at: :desc) }
  scope :parsed, -> { where.not(parsed_at: nil) }
  scope :unparsed, -> { where(parsed_at: nil) }

  # Content type constants
  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    text/plain
    text/rtf
    application/rtf
  ].freeze

  CONTENT_TYPE_LABELS = {
    "application/pdf" => "PDF",
    "application/msword" => "Word (DOC)",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => "Word (DOCX)",
    "text/plain" => "Text",
    "text/rtf" => "RTF",
    "application/rtf" => "RTF"
  }.freeze

  # Status helpers
  def parsed?
    parsed_at.present?
  end

  def file_type_label
    CONTENT_TYPE_LABELS[content_type] || content_type
  end

  def file_size_formatted
    if file_size < 1.kilobyte
      "#{file_size} B"
    elsif file_size < 1.megabyte
      "#{(file_size / 1.kilobyte.to_f).round(1)} KB"
    else
      "#{(file_size / 1.megabyte.to_f).round(2)} MB"
    end
  end

  # Primary resume management
  def make_primary!
    transaction do
      candidate.resumes.where.not(id: id).update_all(primary: false)
      update!(primary: true)
    end
  end

  # Parsing (placeholder for future implementation)
  def mark_as_parsed!(text: nil, data: {})
    update!(
      raw_text: text,
      parsed_data: data,
      parsed_at: Time.current
    )
  end

  # Generate download URL
  def download_url(expires_in: 1.hour)
    return nil unless file.attached?

    Rails.application.routes.url_helpers.rails_blob_path(file, disposition: "attachment", expires_in: expires_in)
  end

  def preview_url(expires_in: 1.hour)
    return nil unless file.attached?

    Rails.application.routes.url_helpers.rails_blob_path(file, disposition: "inline", expires_in: expires_in)
  end

  private

  def set_file_attributes
    self.filename ||= file.blob.filename.to_s
    self.content_type ||= file.blob.content_type
    self.file_size ||= file.blob.byte_size
    self.storage_key ||= file.blob.key
  end

  def acceptable_file_type
    return unless content_type.present?

    unless ALLOWED_CONTENT_TYPES.include?(content_type)
      errors.add(:file, "must be a PDF, Word document, or text file")
    end
  end

  def ensure_single_primary
    candidate.resumes.where.not(id: id).update_all(primary: false)
  end
end
