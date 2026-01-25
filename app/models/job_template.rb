# frozen_string_literal: true

class JobTemplate < ApplicationRecord
  include OrganizationScoped

  # Fallback constants (shared with Job)
  EMPLOYMENT_TYPES = Job::EMPLOYMENT_TYPES
  LOCATION_TYPES = Job::LOCATION_TYPES

  # Associations
  belongs_to :department, optional: true

  # Validations
  validates :name, presence: true,
                   length: { maximum: 255 },
                   uniqueness: { scope: :organization_id }
  validates :title, presence: true, length: { maximum: 255 }
  validates :employment_type, presence: true
  validates :location_type, presence: true
  validates :default_headcount, numericality: { only_integer: true, greater_than: 0 }
  validates :salary_min, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :salary_max, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  validate :salary_range_valid
  validate :employment_type_in_lookup
  validate :location_type_in_lookup

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_department, ->(department_id) { where(department_id: department_id) }
  scope :ordered, -> { order(name: :asc) }

  # Create a job from this template
  def create_job(attributes = {})
    organization.jobs.new(
      template_attributes.merge(attributes)
    )
  end

  # Build a job without saving
  def build_job(attributes = {})
    Job.new(
      template_attributes.merge(
        organization: organization
      ).merge(attributes)
    )
  end

  # Attributes that transfer to a job
  def template_attributes
    {
      department: department,
      title: title,
      description: description,
      requirements: requirements,
      location_type: location_type,
      employment_type: employment_type,
      salary_min: salary_min,
      salary_max: salary_max,
      salary_currency: salary_currency,
      headcount: default_headcount
    }
  end

  # Activation
  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end

  # Display helpers
  def employment_type_display
    LookupService.translate("employment_type", employment_type, organization: organization)
  end

  def location_type_display
    LookupService.translate("location_type", location_type, organization: organization)
  end

  private

  def salary_range_valid
    return unless salary_min && salary_max
    return if salary_max >= salary_min

    errors.add(:salary_max, "must be greater than or equal to minimum salary")
  end

  def employment_type_in_lookup
    return if employment_type.blank?

    valid_types = lookup_codes_for("employment_type")
    return if valid_types.include?(employment_type)

    errors.add(:employment_type, "is not a valid employment type")
  end

  def location_type_in_lookup
    return if location_type.blank?

    valid_types = lookup_codes_for("location_type")
    return if valid_types.include?(location_type)

    errors.add(:location_type, "is not a valid location type")
  end

  def lookup_codes_for(type_code)
    if organization
      LookupService.valid_codes(type_code, organization: organization)
    else
      case type_code
      when "employment_type" then EMPLOYMENT_TYPES
      when "location_type" then LOCATION_TYPES
      else []
      end
    end
  end
end
