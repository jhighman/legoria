# frozen_string_literal: true

class CandidateNote < ApplicationRecord
  # Visibility levels
  VISIBILITIES = %w[private team hiring_team].freeze

  # Associations
  belongs_to :candidate
  belongs_to :user

  # Validations
  validates :content, presence: true, length: { maximum: 10_000 }
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }

  # Scopes
  scope :pinned, -> { where(pinned: true) }
  scope :unpinned, -> { where(pinned: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :pinned_first, -> { order(pinned: :desc, created_at: :desc) }

  scope :visible_to, ->(user) {
    return all if user.admin?

    where(visibility: "team")
      .or(where(visibility: "private", user_id: user.id))
      .or(where(visibility: "hiring_team"))
  }

  scope :by_visibility, ->(visibility) {
    return all if visibility.blank?

    where(visibility: visibility)
  }

  # Visibility helpers
  def private?
    visibility == "private"
  end

  def team_visible?
    visibility == "team"
  end

  def hiring_team_visible?
    visibility == "hiring_team"
  end

  def visible_to?(user)
    return true if user.admin?
    return true if visibility == "team"
    return true if visibility == "private" && user_id == user.id
    return true if visibility == "hiring_team" && user_on_hiring_team?(user)

    false
  end

  # Pin management
  def pin!
    update!(pinned: true)
  end

  def unpin!
    update!(pinned: false)
  end

  def toggle_pin!
    update!(pinned: !pinned)
  end

  # Display helpers
  def visibility_label
    case visibility
    when "private" then "Private"
    when "team" then "Team"
    when "hiring_team" then "Hiring Team"
    else visibility.titleize
    end
  end

  def visibility_icon
    case visibility
    when "private" then "lock"
    when "team" then "users"
    when "hiring_team" then "briefcase"
    else "eye"
    end
  end

  def author_name
    user&.full_name || "Unknown"
  end

  def excerpt(length: 100)
    content.truncate(length)
  end

  private

  def user_on_hiring_team?(user)
    # Check if user is hiring manager for any of the candidate's active applications
    candidate.applications
             .active
             .joins(:job)
             .where(jobs: { hiring_manager_id: user.id })
             .exists?
  end
end
