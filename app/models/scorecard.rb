# frozen_string_literal: true

class Scorecard < ApplicationRecord
  include OrganizationScoped
  include Auditable

  # Audit configuration
  audit_actions create: "scorecard.created", update: "scorecard.updated"
  audit_exclude :summary, :strengths, :concerns

  # Status constants
  STATUSES = %w[draft submitted locked].freeze

  # Recommendation levels
  RECOMMENDATIONS = %w[strong_hire hire no_decision no_hire strong_no_hire].freeze

  # Associations
  belongs_to :interview
  belongs_to :interview_participant
  belongs_to :scorecard_template, optional: true

  has_many :scorecard_responses, dependent: :destroy

  # Delegations
  delegate :application, to: :interview
  delegate :job, to: :interview
  delegate :candidate, to: :application
  delegate :user, to: :interview_participant

  # Nested attributes for responses
  accepts_nested_attributes_for :scorecard_responses,
                                allow_destroy: false,
                                reject_if: :all_blank

  # Validations
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :overall_recommendation, inclusion: { in: RECOMMENDATIONS }, allow_blank: true
  validates :overall_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  validates :interview_participant_id, uniqueness: { message: "has already submitted a scorecard for this interview" }

  validate :interview_completed, on: :create
  validate :required_fields_for_submission, if: :submitting?

  # Callbacks
  before_save :calculate_overall_score

  # State machine for scorecard workflow
  state_machine :status, initial: :draft do
    state :draft
    state :submitted
    state :locked

    event :submit do
      transition draft: :submitted
    end

    event :lock_scorecard do
      transition submitted: :locked
    end

    event :unlock_scorecard do
      transition locked: :submitted
    end

    event :revert_to_draft do
      transition submitted: :draft
    end

    after_transition to: :submitted do |scorecard|
      scorecard.update_column(:submitted_at, Time.current)
      scorecard.interview_participant.submit_feedback!
      scorecard.update_column(:visible_to_team, true)
    end

    after_transition to: :locked do |scorecard|
      scorecard.update_column(:locked_at, Time.current)
    end
  end

  # Scopes
  scope :drafts, -> { where(status: "draft") }
  scope :submitted, -> { where(status: "submitted") }
  scope :locked, -> { where(status: "locked") }
  scope :completed, -> { where(status: %w[submitted locked]) }
  scope :visible, -> { where(visible_to_team: true) }
  scope :for_interview, ->(interview_id) { where(interview_id: interview_id) }
  scope :for_application, ->(application_id) { joins(:interview).where(interviews: { application_id: application_id }) }
  scope :by_recommendation, ->(rec) { where(overall_recommendation: rec) if rec.present? }

  # Status helpers
  def draft?
    status == "draft"
  end

  def submitted?
    status == "submitted"
  end

  def locked?
    status == "locked"
  end

  def editable?
    draft?
  end

  # Response management
  def response_for(item)
    scorecard_responses.find_by(scorecard_template_item_id: item.id)
  end

  def set_response(item, value:, notes: nil)
    response = scorecard_responses.find_or_initialize_by(scorecard_template_item_id: item.id)

    case item.item_type
    when "rating"
      response.rating = value
    when "yes_no"
      response.yes_no_value = value
    when "text"
      response.text_value = value
    when "select"
      response.select_value = value
    end

    response.notes = notes if notes.present?
    response.save!
    response
  end

  def completion_percentage
    return 0 unless scorecard_template

    required_items = scorecard_template.scorecard_template_items.required
    return 100 if required_items.empty?

    answered = scorecard_responses.where(scorecard_template_item_id: required_items.pluck(:id)).count
    ((answered.to_f / required_items.count) * 100).round
  end

  # Recommendation helpers
  def recommendation_label
    return nil unless overall_recommendation

    case overall_recommendation
    when "strong_hire" then "Strong Hire"
    when "hire" then "Hire"
    when "no_decision" then "No Decision"
    when "no_hire" then "No Hire"
    when "strong_no_hire" then "Strong No Hire"
    else overall_recommendation.titleize
    end
  end

  def recommendation_color
    case overall_recommendation
    when "strong_hire" then "green"
    when "hire" then "emerald"
    when "no_decision" then "gray"
    when "no_hire" then "orange"
    when "strong_no_hire" then "red"
    else "gray"
    end
  end

  def positive_recommendation?
    overall_recommendation.in?(%w[strong_hire hire])
  end

  def negative_recommendation?
    overall_recommendation.in?(%w[no_hire strong_no_hire])
  end

  # Display helpers
  def interviewer_name
    interview_participant.user.full_name
  end

  def status_label
    status.titleize
  end

  def status_color
    case status
    when "draft" then "yellow"
    when "submitted" then "green"
    when "locked" then "gray"
    else "gray"
    end
  end

  private

  def submitting?
    will_save_change_to_status? && status == "submitted"
  end

  def interview_completed
    return if interview.blank?

    errors.add(:interview, "must be completed before submitting feedback") unless interview.completed?
  end

  def required_fields_for_submission
    errors.add(:overall_recommendation, "is required") if overall_recommendation.blank?
    errors.add(:summary, "is required") if summary.blank?

    return unless scorecard_template

    required_items = scorecard_template.scorecard_template_items.required
    answered_item_ids = scorecard_responses.pluck(:scorecard_template_item_id)

    missing = required_items.where.not(id: answered_item_ids)
    errors.add(:base, "Please complete all required fields") if missing.any?
  end

  def calculate_overall_score
    return unless scorecard_template
    return if scorecard_responses.empty?

    rating_responses = scorecard_responses.joins(scorecard_template_item: :scorecard_template_section)
                                          .where(scorecard_template_items: { item_type: "rating" })
                                          .includes(scorecard_template_item: :scorecard_template_section)

    return if rating_responses.empty?

    total_weight = 0
    weighted_sum = 0

    rating_responses.each do |response|
      next unless response.rating.present?

      item = response.scorecard_template_item
      section = item.scorecard_template_section
      weight = section.weight || 100
      max_rating = item.rating_scale || 5

      normalized_score = (response.rating.to_f / max_rating) * 100
      weighted_sum += normalized_score * weight
      total_weight += weight
    end

    self.overall_score = total_weight.positive? ? (weighted_sum / total_weight).round(2) : nil
  end
end
