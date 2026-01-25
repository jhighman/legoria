# frozen_string_literal: true

# SA-11: Integration - Job board posting tracking
# Tracks job postings to external job boards like Indeed, LinkedIn, etc.
class JobBoardPosting < ApplicationRecord
  # Associations
  belongs_to :organization, optional: true
  belongs_to :job
  belongs_to :integration, optional: true
  belongs_to :posted_by, class_name: "User", optional: true

  # Status workflow
  STATUSES = %w[pending active posted updated expired removed error failed].freeze

  # Validations
  validates :board_name, presence: true
  validates :status, inclusion: { in: STATUSES }

  # Scopes
  scope :active, -> { where(status: %w[active posted updated]) }
  scope :pending, -> { where(status: "pending") }
  scope :failed, -> { where(status: %w[error failed]) }
  scope :expired, -> { where(status: "expired") }
  scope :for_job, ->(job) { where(job: job) }
  scope :for_board, ->(board) { where(board_name: board) }
  scope :expiring_soon, -> { active.where("expires_at <= ?", 7.days.from_now) }
  scope :needs_sync, -> { where("last_synced_at IS NULL OR last_synced_at < ?", 1.hour.ago) }

  # State checks
  def pending?
    status == "pending"
  end

  def active?
    status.in?(%w[active posted updated])
  end

  def expired?
    status == "expired" || (expires_at.present? && expires_at < Time.current)
  end

  def removed?
    status == "removed"
  end

  def failed?
    status.in?(%w[error failed])
  end

  # Workflow actions
  def mark_posted!(external_id: nil, external_url: nil, expires_at: nil)
    update!(
      status: "posted",
      external_id: external_id,
      external_url: external_url,
      posted_at: Time.current,
      expires_at: expires_at,
      last_synced_at: Time.current,
      last_error: nil
    )
  end

  def mark_updated!
    update!(
      status: "updated",
      last_synced_at: Time.current,
      last_error: nil
    )
  end

  def mark_expired!
    update!(
      status: "expired",
      last_synced_at: Time.current
    )
  end

  def mark_removed!(removed_at: nil)
    update!(
      status: "removed",
      removed_at: removed_at || Time.current,
      last_synced_at: Time.current
    )
  end

  def mark_error!(error_message)
    update!(
      status: "error",
      last_error: error_message,
      last_synced_at: Time.current
    )
  end

  def update_stats!(views: nil, clicks: nil, applications: nil)
    attrs = { last_synced_at: Time.current }
    attrs[:views_count] = views if views
    attrs[:clicks_count] = clicks if clicks
    attrs[:applications_count] = applications if applications
    update!(attrs)
  end

  def sync_needed?
    last_synced_at.nil? || last_synced_at < 1.hour.ago
  end

  def check_expiration!
    return unless expires_at.present? && expires_at < Time.current && active?

    mark_expired!
  end
end
