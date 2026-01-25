# frozen_string_literal: true

module Reports
  class WorkAuthorizationsController < BaseController
    def index
      @data = work_authorization_data
      @authorization_types = WorkAuthorization::AUTHORIZATION_TYPES

      respond_to do |format|
        format.html
        format.json { render json: chart_data }
      end
    end

    def expiring
      @expiring_30 = scoped_authorizations.expiring_soon(30).includes(:candidate).order(:valid_until)
      @expiring_60 = scoped_authorizations.expiring_soon(60).where("valid_until > ?", 30.days.from_now).includes(:candidate).order(:valid_until)
      @expiring_90 = scoped_authorizations.expiring_soon(90).where("valid_until > ?", 60.days.from_now).includes(:candidate).order(:valid_until)
    end

    def export
      authorize :report, :export?

      csv = generate_csv
      send_csv(csv, "work_authorizations_report")
    end

    private

    def report_title
      "Work Authorizations"
    end

    def report_description
      "Work authorization status and expiration tracking"
    end

    def scoped_authorizations
      WorkAuthorization.where(organization_id: current_organization.id)
    end

    def work_authorization_data
      total = scoped_authorizations.count
      indefinite = scoped_authorizations.where(indefinite: true).count
      expiring_30 = scoped_authorizations.expiring_soon(30).count
      expiring_60 = scoped_authorizations.expiring_soon(60).count
      expiring_90 = scoped_authorizations.expiring_soon(90).count
      needs_reverification = scoped_authorizations.where(reverification_required: true).count

      {
        summary: {
          total: total,
          indefinite: indefinite,
          temporary: total - indefinite,
          expiring_30_days: expiring_30,
          expiring_60_days: expiring_60,
          expiring_90_days: expiring_90,
          needs_reverification: needs_reverification
        },
        by_type: authorization_type_breakdown,
        expiration_timeline: expiration_timeline_data,
        recent: recent_authorizations
      }
    end

    def authorization_type_breakdown
      scoped_authorizations
        .group(:authorization_type)
        .count
        .map do |type, count|
          {
            type: type,
            type_label: type.titleize.gsub("_", " "),
            count: count,
            indefinite_count: scoped_authorizations.where(authorization_type: type, indefinite: true).count
          }
        end
        .sort_by { |t| -t[:count] }
    end

    def expiration_timeline_data
      # Group by month for next 12 months
      start_month = Date.current.beginning_of_month
      months = (0..11).map { |i| start_month + i.months }

      months.map do |month|
        month_end = month.end_of_month
        count = scoped_authorizations
          .where(indefinite: false)
          .where(valid_until: month..month_end)
          .count

        {
          month: month,
          label: month.strftime("%b %Y"),
          expiring_count: count
        }
      end
    end

    def recent_authorizations
      scoped_authorizations
        .includes(:candidate, :i9_verification)
        .order(created_at: :desc)
        .limit(20)
        .map do |auth|
          {
            id: auth.id,
            candidate_name: auth.candidate.full_name,
            type: auth.authorization_type.titleize,
            valid_from: auth.valid_from,
            valid_until: auth.valid_until,
            indefinite: auth.indefinite?,
            days_until_expiration: auth.days_until_expiration,
            needs_reverification: auth.needs_reverification?
          }
        end
    end

    def chart_data
      {
        type_distribution: {
          labels: @data[:by_type].map { |t| t[:type_label] },
          datasets: [{
            data: @data[:by_type].map { |t| t[:count] },
            backgroundColor: type_colors
          }]
        },
        expiration_timeline: {
          labels: @data[:expiration_timeline].map { |t| t[:label] },
          datasets: [{
            label: "Expiring Authorizations",
            data: @data[:expiration_timeline].map { |t| t[:expiring_count] },
            borderColor: "#EF4444",
            backgroundColor: "rgba(239, 68, 68, 0.1)",
            fill: true
          }]
        }
      }
    end

    def type_colors
      [
        "#10B981", # citizen - green
        "#3B82F6", # permanent_resident - blue
        "#8B5CF6", # ead - purple
        "#F59E0B", # h1b - amber
        "#EC4899", # opt - pink
        "#14B8A6", # cpt - teal
        "#F97316", # tn - orange
        "#6366F1", # l1 - indigo
        "#6B7280"  # other - gray
      ]
    end

    def generate_csv
      require "csv"

      authorizations = scoped_authorizations
        .includes(:candidate)
        .order(:valid_until)

      CSV.generate(headers: true) do |csv|
        csv << ["Candidate", "Authorization Type", "Valid From", "Valid Until",
                "Indefinite", "Days Until Expiration", "Needs Reverification"]

        authorizations.each do |auth|
          csv << [
            auth.candidate.full_name,
            auth.authorization_type.titleize,
            auth.valid_from&.strftime("%Y-%m-%d"),
            auth.valid_until&.strftime("%Y-%m-%d"),
            auth.indefinite? ? "Yes" : "No",
            auth.days_until_expiration,
            auth.needs_reverification? ? "Yes" : "No"
          ]
        end
      end
    end
  end
end
