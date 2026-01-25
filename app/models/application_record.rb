# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Common timestamp formatting
  def created_at_formatted
    created_at&.strftime("%B %d, %Y at %I:%M %p")
  end

  def updated_at_formatted
    updated_at&.strftime("%B %d, %Y at %I:%M %p")
  end
end
