# frozen_string_literal: true

class RolePermission < ApplicationRecord
  # Associations
  belongs_to :role
  belongs_to :permission

  # Validations
  validates :role_id, uniqueness: { scope: :permission_id }

  # Conditions allow fine-grained permission control
  # e.g., { "own_only" => true } means user can only access their own records
  def condition_met?(context = {})
    return true if conditions.blank?

    conditions.all? do |key, value|
      case key
      when "own_only"
        context[:record]&.respond_to?(:user_id) && context[:record].user_id == context[:user]&.id
      when "department_only"
        context[:record]&.respond_to?(:department_id) && context[:user]&.department_ids&.include?(context[:record].department_id)
      else
        true
      end
    end
  end
end
