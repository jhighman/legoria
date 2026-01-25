# frozen_string_literal: true

# Phase 3: Enhanced Candidate Experience - Organization branding for career site
class CreateOrganizationBrandings < ActiveRecord::Migration[8.0]
  def change
    create_table :organization_brandings do |t|
      t.references :organization, null: false, foreign_key: true, index: { unique: true }

      # Brand colors
      t.string :primary_color, default: "#0d6efd"
      t.string :secondary_color, default: "#6c757d"
      t.string :accent_color, default: "#0dcaf0"
      t.string :text_color, default: "#212529"
      t.string :background_color, default: "#ffffff"

      # Typography
      t.string :font_family, default: "system-ui, -apple-system, sans-serif"
      t.string :heading_font_family

      # Custom CSS (advanced users)
      t.text :custom_css

      # Content
      t.string :company_tagline
      t.text :about_company
      t.text :benefits_summary
      t.text :culture_description

      # Social links
      t.string :linkedin_url
      t.string :twitter_url
      t.string :facebook_url
      t.string :instagram_url
      t.string :glassdoor_url

      # SEO
      t.string :meta_title
      t.text :meta_description
      t.string :meta_keywords

      # Career site settings
      t.boolean :show_salary_ranges, null: false, default: false
      t.boolean :show_department_filter, null: false, default: true
      t.boolean :show_location_filter, null: false, default: true
      t.boolean :show_employment_type_filter, null: false, default: true
      t.boolean :enable_job_alerts, null: false, default: false

      t.timestamps
    end
  end
end
