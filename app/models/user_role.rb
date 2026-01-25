# frozen_string_literal: true

class UserRole < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :role
  belongs_to :granted_by, class_name: "User", optional: true

  # Validations
  validates :user_id, uniqueness: { scope: :role_id, message: "already has this role" }
  validates :granted_at, presence: true

  # Callbacks
  before_validation :set_granted_at, on: :create

  # Scopes
  scope :recent, -> { order(granted_at: :desc) }

  private

  def set_granted_at
    self.granted_at ||= Time.current
  end
end
