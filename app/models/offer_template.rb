# frozen_string_literal: true

class OfferTemplate < ApplicationRecord
  include OrganizationScoped

  # Template types
  TEMPLATE_TYPES = %w[standard executive contractor intern].freeze

  # Default variables available for substitution
  DEFAULT_VARIABLES = %w[
    candidate_name candidate_first_name candidate_email
    job_title department location
    salary salary_period currency
    signing_bonus annual_bonus_target
    equity_type equity_shares equity_vesting_schedule
    start_date employment_type
    reports_to company_name
    offer_expiration_date
  ].freeze

  # Associations
  has_many :offers, dependent: :nullify

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :body, presence: true
  validates :template_type, presence: true, inclusion: { in: TEMPLATE_TYPES }

  # Callbacks
  before_save :set_default_variables

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_type, ->(type) { where(template_type: type) if type.present? }
  scope :defaults, -> { where(is_default: true) }

  # Type helpers
  def standard?
    template_type == "standard"
  end

  def executive?
    template_type == "executive"
  end

  def contractor?
    template_type == "contractor"
  end

  def intern?
    template_type == "intern"
  end

  # Template rendering
  def render(variables = {})
    content = body.dup

    # Substitute variables
    merged_variables = default_variable_values.merge(variables.stringify_keys)
    merged_variables.each do |key, value|
      content.gsub!("{{#{key}}}", value.to_s)
    end

    content
  end

  def render_subject(variables = {})
    return nil unless subject_line

    content = subject_line.dup
    merged_variables = default_variable_values.merge(variables.stringify_keys)
    merged_variables.each do |key, value|
      content.gsub!("{{#{key}}}", value.to_s)
    end

    content
  end

  # Variable management
  def variables_list
    available_variables.presence || DEFAULT_VARIABLES
  end

  def add_variable(name)
    self.available_variables ||= DEFAULT_VARIABLES.dup
    self.available_variables << name unless available_variables.include?(name)
  end

  # Display helpers
  def template_type_label
    template_type.titleize
  end

  # Duplication
  def duplicate
    dup.tap do |new_template|
      new_template.name = "#{name} (Copy)"
      new_template.is_default = false
    end
  end

  # Activation
  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end

  def make_default!
    transaction do
      # Remove default from other templates of same type
      organization.offer_templates
                  .where(template_type: template_type)
                  .where.not(id: id)
                  .update_all(is_default: false)

      update!(is_default: true)
    end
  end

  private

  def set_default_variables
    self.available_variables ||= DEFAULT_VARIABLES.dup
  end

  def default_variable_values
    {
      "company_name" => organization&.name || ""
    }
  end
end
