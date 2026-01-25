# frozen_string_literal: true

# Discardable provides soft delete functionality.
#
# Include this concern in models that should support soft delete:
#
#   class Job < ApplicationRecord
#     include Discardable
#   end
#
# This provides:
# - discarded_at timestamp for soft deletes
# - discard/undiscard methods
# - kept/discarded scopes
# - Default scope excludes discarded records
#
module Discardable
  extend ActiveSupport::Concern

  included do
    scope :kept, -> { where(discarded_at: nil) }
    scope :discarded, -> { where.not(discarded_at: nil) }
    scope :with_discarded, -> { unscope(where: :discarded_at) }

    default_scope { kept }
  end

  def discard
    update(discarded_at: Time.current)
  end

  def discard!
    update!(discarded_at: Time.current)
  end

  def undiscard
    update(discarded_at: nil)
  end

  def undiscard!
    update!(discarded_at: nil)
  end

  def discarded?
    discarded_at.present?
  end

  def kept?
    discarded_at.nil?
  end
end
