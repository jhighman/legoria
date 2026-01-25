# frozen_string_literal: true

class Offer < ApplicationRecord
  include OrganizationScoped
  include Auditable

  # Status constants
  STATUSES = %w[draft pending_approval approved sent accepted declined withdrawn expired].freeze
  SALARY_PERIODS = %w[yearly monthly hourly].freeze
  EQUITY_TYPES = %w[options rsu none].freeze
  EMPLOYMENT_TYPES = %w[full_time part_time contractor intern].freeze

  # Associations
  belongs_to :application
  belongs_to :offer_template, optional: true
  belongs_to :created_by, class_name: "User"

  has_many :offer_approvals, dependent: :destroy

  # Delegations
  delegate :candidate, :job, to: :application
  delegate :name, to: :candidate, prefix: true
  delegate :title, to: :job, prefix: true

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :salary_period, inclusion: { in: SALARY_PERIODS }, allow_nil: true
  validates :equity_type, inclusion: { in: EQUITY_TYPES }, allow_nil: true
  validates :employment_type, inclusion: { in: EMPLOYMENT_TYPES }, allow_nil: true

  validates :salary, numericality: { greater_than: 0 }, allow_nil: true
  validates :signing_bonus, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :annual_bonus_target, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :equity_shares, numericality: { greater_than: 0, only_integer: true }, allow_nil: true

  validate :expires_at_in_future, on: :create

  # Scopes
  scope :drafts, -> { where(status: "draft") }
  scope :pending_approval, -> { where(status: "pending_approval") }
  scope :approved, -> { where(status: "approved") }
  scope :sent, -> { where(status: "sent") }
  scope :accepted, -> { where(status: "accepted") }
  scope :declined, -> { where(status: "declined") }
  scope :active, -> { where(status: %w[draft pending_approval approved sent]) }
  scope :responded, -> { where(status: %w[accepted declined]) }
  scope :expiring_soon, -> { where(status: "sent").where("expires_at <= ?", 3.days.from_now) }

  # Status helpers
  def draft?
    status == "draft"
  end

  def pending_approval?
    status == "pending_approval"
  end

  def approved?
    status == "approved"
  end

  def sent?
    status == "sent"
  end

  def accepted?
    status == "accepted"
  end

  def declined?
    status == "declined"
  end

  def withdrawn?
    status == "withdrawn"
  end

  def expired?
    status == "expired"
  end

  def can_edit?
    draft? || pending_approval?
  end

  def can_submit_for_approval?
    draft?
  end

  def can_approve?
    pending_approval?
  end

  def can_send?
    approved?
  end

  def can_respond?
    sent? && !past_expiration?
  end

  def past_expiration?
    expires_at.present? && expires_at < Time.current
  end

  # Workflow actions
  def submit_for_approval!
    raise StandardError, "Cannot submit - offer must be in draft status" unless draft?

    update!(status: "pending_approval")
  end

  def approve!
    raise StandardError, "Cannot approve - offer must be pending approval" unless pending_approval?

    update!(status: "approved")
  end

  def reject_approval!(reason = nil)
    raise StandardError, "Cannot reject - offer must be pending approval" unless pending_approval?

    update!(status: "draft", custom_terms: [custom_terms, "Rejection reason: #{reason}"].compact.join("\n\n"))
  end

  def send_to_candidate!
    raise StandardError, "Cannot send - offer must be approved" unless approved?

    update!(status: "sent", sent_at: Time.current)
  end

  def mark_accepted!
    raise StandardError, "Cannot accept - offer must be sent" unless sent?

    transaction do
      update!(
        status: "accepted",
        response: "accepted",
        responded_at: Time.current
      )

      # Move application to offered stage if not already
      application.offer! if application.can_offer?
    end
  end

  def mark_declined!(reason = nil)
    raise StandardError, "Cannot decline - offer must be sent" unless sent?

    update!(
      status: "declined",
      response: "declined",
      decline_reason: reason,
      responded_at: Time.current
    )
  end

  def withdraw!
    raise StandardError, "Cannot withdraw - offer already responded to" if accepted? || declined?

    update!(status: "withdrawn")
  end

  def check_expiration!
    return unless sent? && past_expiration?

    update!(status: "expired")
  end

  # Compensation helpers
  def total_first_year_compensation
    total = salary || 0

    # Adjust for salary period
    annual_salary = case salary_period
    when "monthly" then total * 12
    when "hourly" then total * 2080 # 40 hours * 52 weeks
    else total
    end

    annual_salary += signing_bonus || 0

    if annual_bonus_target.present? && annual_salary > 0
      annual_salary += (salary || 0) * (annual_bonus_target / 100.0)
    end

    annual_salary
  end

  def compensation_summary
    parts = []
    parts << "#{formatted_salary}/#{salary_period}" if salary.present?
    parts << "#{formatted_signing_bonus} signing bonus" if signing_bonus.present? && signing_bonus > 0
    parts << "#{annual_bonus_target}% target bonus" if annual_bonus_target.present? && annual_bonus_target > 0
    parts << "#{equity_shares} #{equity_type}" if equity_shares.present? && equity_type != "none"
    parts.join(" + ")
  end

  def formatted_salary
    return nil unless salary

    number_to_currency(salary)
  end

  def formatted_signing_bonus
    return nil unless signing_bonus

    number_to_currency(signing_bonus)
  end

  # Template rendering
  def render_from_template!
    return unless offer_template

    variables = template_variables
    self.rendered_content = offer_template.render(variables)
  end

  def template_variables
    {
      "candidate_name" => candidate.full_name,
      "candidate_first_name" => candidate.first_name,
      "candidate_email" => candidate.email,
      "job_title" => title,
      "department" => department,
      "location" => work_location,
      "salary" => formatted_salary,
      "salary_period" => salary_period,
      "currency" => currency,
      "signing_bonus" => formatted_signing_bonus,
      "annual_bonus_target" => annual_bonus_target.present? ? "#{annual_bonus_target}%" : nil,
      "equity_type" => equity_type,
      "equity_shares" => equity_shares,
      "equity_vesting_schedule" => equity_vesting_schedule,
      "start_date" => proposed_start_date&.strftime("%B %d, %Y"),
      "employment_type" => employment_type&.titleize&.gsub("_", " "),
      "reports_to" => reports_to,
      "company_name" => organization.name,
      "offer_expiration_date" => expires_at&.strftime("%B %d, %Y")
    }.compact
  end

  # Display helpers
  def status_label
    status.titleize.gsub("_", " ")
  end

  def status_color
    case status
    when "draft" then "gray"
    when "pending_approval" then "yellow"
    when "approved" then "blue"
    when "sent" then "purple"
    when "accepted" then "green"
    when "declined" then "red"
    when "withdrawn" then "orange"
    when "expired" then "gray"
    else "gray"
    end
  end

  def days_until_expiration
    return nil unless expires_at

    (expires_at.to_date - Date.current).to_i
  end

  private

  def expires_at_in_future
    return unless expires_at.present? && expires_at <= Time.current

    errors.add(:expires_at, "must be in the future")
  end

  def number_to_currency(number)
    return nil unless number

    "$#{number.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
end
