# frozen_string_literal: true

class ScorecardTemplate < ApplicationRecord
  include OrganizationScoped

  # Associations
  belongs_to :job, optional: true
  belongs_to :stage, optional: true

  has_many :scorecard_template_sections, -> { order(position: :asc) }, dependent: :destroy
  has_many :scorecard_template_items, through: :scorecard_template_sections
  has_many :scorecards, dependent: :nullify

  # Nested attributes for building templates
  accepts_nested_attributes_for :scorecard_template_sections,
                                allow_destroy: true,
                                reject_if: :all_blank

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :interview_type, inclusion: { in: Interview::INTERVIEW_TYPES }, allow_blank: true

  validate :only_one_default_per_scope

  # Callbacks
  before_save :ensure_single_default

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :defaults, -> { where(is_default: true) }
  scope :for_job, ->(job_id) { where(job_id: job_id).or(where(job_id: nil)) }
  scope :for_stage, ->(stage_id) { where(stage_id: stage_id).or(where(stage_id: nil)) }
  scope :for_interview_type, ->(type) { where(interview_type: type).or(where(interview_type: nil)) }

  # Find the best matching template for an interview
  def self.find_for_interview(interview)
    # Priority: exact match > job match > stage match > default
    candidates = active
                   .for_job(interview.job_id)
                   .for_interview_type(interview.interview_type)

    # Try exact match with stage from application
    stage_id = interview.application.current_stage_id
    exact_match = candidates.where(job_id: interview.job_id, stage_id: stage_id).first
    return exact_match if exact_match

    # Try job match without stage
    job_match = candidates.where(job_id: interview.job_id, stage_id: nil).first
    return job_match if job_match

    # Fall back to organization default
    candidates.defaults.first || candidates.first
  end

  # Template building helpers
  def add_section(name:, section_type: "competencies", **attributes)
    max_position = scorecard_template_sections.maximum(:position) || -1
    scorecard_template_sections.create!(
      name: name,
      section_type: section_type,
      position: max_position + 1,
      **attributes
    )
  end

  def duplicate(new_name: nil)
    dup_template = dup
    dup_template.name = new_name || "#{name} (Copy)"
    dup_template.is_default = false

    scorecard_template_sections.includes(:scorecard_template_items).each do |section|
      dup_section = section.dup
      dup_template.scorecard_template_sections << dup_section

      section.scorecard_template_items.each do |item|
        dup_item = item.dup
        dup_section.scorecard_template_items << dup_item
      end
    end

    dup_template.save!
    dup_template
  end

  # Status helpers
  def active?
    active
  end

  def default?
    is_default
  end

  # Display helpers
  def item_count
    scorecard_template_items.count
  end

  def section_count
    scorecard_template_sections.count
  end

  def scope_description
    parts = []
    parts << "Job: #{job.title}" if job
    parts << "Stage: #{stage.name}" if stage
    parts << "Type: #{interview_type.titleize}" if interview_type.present?
    parts.empty? ? "Organization-wide" : parts.join(", ")
  end

  private

  def only_one_default_per_scope
    return unless is_default && is_default_changed?

    existing = ScorecardTemplate.kept
                                .where(organization_id: organization_id, is_default: true)
                                .where.not(id: id)
                                .where(job_id: job_id, stage_id: stage_id, interview_type: interview_type)

    errors.add(:is_default, "already exists for this scope") if existing.exists?
  end

  def ensure_single_default
    return unless is_default && is_default_changed?

    # Unset any other defaults with the same scope
    ScorecardTemplate.kept
                     .where(organization_id: organization_id, is_default: true)
                     .where.not(id: id)
                     .where(job_id: job_id, stage_id: stage_id, interview_type: interview_type)
                     .update_all(is_default: false)
  end
end
