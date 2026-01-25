# frozen_string_literal: true

class InterviewKit < ApplicationRecord
  include OrganizationScoped

  # Interview types (same as Interview model)
  INTERVIEW_TYPES = %w[phone_screen video onsite panel technical cultural_fit].freeze

  # Associations
  belongs_to :job, optional: true
  belongs_to :stage, optional: true

  has_many :interview_kit_questions, -> { order(position: :asc) }, dependent: :destroy
  has_many :question_banks, through: :interview_kit_questions

  # Nested attributes for questions
  accepts_nested_attributes_for :interview_kit_questions,
                                allow_destroy: true,
                                reject_if: proc { |attrs| attrs[:question].blank? && attrs[:question_bank_id].blank? }

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :interview_type, inclusion: { in: INTERVIEW_TYPES }, allow_blank: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :defaults, -> { where(is_default: true) }
  scope :by_type, ->(type) { where(interview_type: type) if type.present? }
  scope :for_job, ->(job_id) { where(job_id: job_id) if job_id.present? }
  scope :for_stage, ->(stage_id) { where(stage_id: stage_id) if stage_id.present? }
  scope :search, ->(query) { where("name LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%") if query.present? }

  # Class methods
  def self.find_for_interview(interview)
    # Priority: 1. Job + Stage specific, 2. Job specific, 3. Stage specific, 4. Interview type specific, 5. Default
    org_kits = where(organization_id: interview.organization_id, active: true)

    # Try job + stage specific
    if interview.job_id && interview.application&.current_stage_id
      kit = org_kits.find_by(job_id: interview.job_id, stage_id: interview.application.current_stage_id)
      return kit if kit
    end

    # Try job specific
    if interview.job_id
      kit = org_kits.find_by(job_id: interview.job_id, stage_id: nil)
      return kit if kit
    end

    # Try interview type specific
    if interview.interview_type
      kit = org_kits.find_by(interview_type: interview.interview_type, job_id: nil, stage_id: nil)
      return kit if kit
    end

    # Fallback to default
    org_kits.find_by(is_default: true)
  end

  # Question management
  def add_question(question_bank: nil, question: nil, guidance: nil, time_allocation: nil)
    position = interview_kit_questions.maximum(:position).to_i + 1

    interview_kit_questions.create!(
      question_bank: question_bank,
      question: question,
      guidance: guidance,
      time_allocation: time_allocation,
      position: position
    )
  end

  def remove_question(interview_kit_question_id)
    interview_kit_questions.find(interview_kit_question_id).destroy
    reorder_questions!
  end

  def reorder_questions!(new_order = nil)
    if new_order
      new_order.each_with_index do |question_id, index|
        interview_kit_questions.find(question_id).update!(position: index)
      end
    else
      interview_kit_questions.order(:position).each_with_index do |q, idx|
        q.update_column(:position, idx)
      end
    end
  end

  # Stats
  def total_questions
    interview_kit_questions.count
  end

  def total_time_allocation
    interview_kit_questions.sum(:time_allocation)
  end

  def total_time_formatted
    mins = total_time_allocation.to_i
    return "Not specified" if mins.zero?

    hours = mins / 60
    remaining_mins = mins % 60

    if hours > 0 && remaining_mins > 0
      "#{hours}h #{remaining_mins}m"
    elsif hours > 0
      "#{hours} hour#{'s' if hours > 1}"
    else
      "#{remaining_mins} minutes"
    end
  end

  # Display helpers
  def interview_type_label
    return nil if interview_type.blank?

    interview_type.titleize.gsub("_", " ")
  end

  def scope_label
    parts = []
    parts << job.title if job.present?
    parts << stage.name if stage.present?
    parts << interview_type_label if interview_type.present?
    parts << "Default" if is_default? && parts.empty?

    parts.empty? ? "General" : parts.join(" - ")
  end

  # Activation helpers
  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end

  def set_as_default!
    transaction do
      # Unset other defaults in same organization
      InterviewKit.where(organization_id: organization_id, is_default: true)
                   .where.not(id: id)
                   .update_all(is_default: false)
      update!(is_default: true)
    end
  end

  # Duplication
  def duplicate(new_name: nil)
    new_kit = dup
    new_kit.name = new_name || "#{name} (Copy)"
    new_kit.is_default = false

    transaction do
      new_kit.save!

      interview_kit_questions.each do |ikq|
        new_kit.interview_kit_questions.create!(
          question_bank_id: ikq.question_bank_id,
          question: ikq.question,
          guidance: ikq.guidance,
          position: ikq.position,
          time_allocation: ikq.time_allocation
        )
      end
    end

    new_kit
  end
end
