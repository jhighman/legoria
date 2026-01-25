# frozen_string_literal: true

class CandidateDocument < ApplicationRecord
  # Document types
  DOCUMENT_TYPES = %w[resume cover_letter portfolio transcript certification reference other].freeze

  # Associations
  belongs_to :candidate
  belongs_to :application, optional: true

  # File attachment
  has_one_attached :file

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :document_type, presence: true, inclusion: { in: DOCUMENT_TYPES }

  validate :file_attached
  validate :file_size_acceptable
  validate :file_type_acceptable

  # Callbacks
  before_save :set_file_metadata

  # Scopes
  scope :visible, -> { where(visible_to_employer: true) }
  scope :hidden, -> { where(visible_to_employer: false) }
  scope :by_type, ->(type) { where(document_type: type) if type.present? }
  scope :resumes, -> { where(document_type: "resume") }
  scope :cover_letters, -> { where(document_type: "cover_letter") }
  scope :portfolios, -> { where(document_type: "portfolio") }
  scope :recent, -> { order(created_at: :desc) }

  # Type helpers
  def resume?
    document_type == "resume"
  end

  def cover_letter?
    document_type == "cover_letter"
  end

  def portfolio?
    document_type == "portfolio"
  end

  def transcript?
    document_type == "transcript"
  end

  def certification?
    document_type == "certification"
  end

  def reference?
    document_type == "reference"
  end

  # Display helpers
  def document_type_label
    document_type.titleize.gsub("_", " ")
  end

  def file_size_formatted
    return "Unknown" unless file_size

    if file_size < 1024
      "#{file_size} B"
    elsif file_size < 1024 * 1024
      "#{(file_size / 1024.0).round(1)} KB"
    else
      "#{(file_size / (1024.0 * 1024)).round(1)} MB"
    end
  end

  def file_extension
    return nil unless original_filename

    File.extname(original_filename).delete(".").upcase
  end

  def downloadable?
    file.attached?
  end

  # Visibility
  def show!
    update_column(:visible_to_employer, true)
  end

  def hide!
    update_column(:visible_to_employer, false)
  end

  def toggle_visibility!
    update_column(:visible_to_employer, !visible_to_employer)
  end

  private

  def file_attached
    unless file.attached?
      errors.add(:file, "must be attached")
    end
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
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      application/vnd.ms-excel
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      image/jpeg
      image/png
      image/gif
      text/plain
    ]

    unless acceptable_types.include?(file.blob.content_type)
      errors.add(:file, "must be a PDF, Word document, Excel spreadsheet, image, or text file")
    end
  end

  def set_file_metadata
    return unless file.attached?

    self.original_filename = file.blob.filename.to_s
    self.content_type = file.blob.content_type
    self.file_size = file.blob.byte_size
  end
end
