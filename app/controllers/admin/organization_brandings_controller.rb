# frozen_string_literal: true

module Admin
  class OrganizationBrandingsController < ApplicationController
    before_action :set_branding

    def show
      authorize @branding
    end

    def edit
      authorize @branding
    end

    def update
      authorize @branding

      if @branding.update(branding_params)
        redirect_to admin_organization_branding_path, notice: "Branding settings updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_branding
      @branding = Current.organization.branding || Current.organization.create_branding!
    end

    def branding_params
      params.require(:organization_branding).permit(
        :primary_color,
        :secondary_color,
        :accent_color,
        :text_color,
        :background_color,
        :font_family,
        :heading_font_family,
        :custom_css,
        :company_tagline,
        :about_company,
        :benefits_summary,
        :culture_description,
        :linkedin_url,
        :twitter_url,
        :facebook_url,
        :instagram_url,
        :glassdoor_url,
        :meta_title,
        :meta_description,
        :meta_keywords,
        :show_salary_ranges,
        :show_department_filter,
        :show_location_filter,
        :show_employment_type_filter,
        :enable_job_alerts,
        :logo,
        :favicon,
        :cover_image
      )
    end
  end
end
