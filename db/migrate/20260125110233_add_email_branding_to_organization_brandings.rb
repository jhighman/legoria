class AddEmailBrandingToOrganizationBrandings < ActiveRecord::Migration[8.0]
  def change
    add_column :organization_brandings, :google_fonts_url, :string
    add_column :organization_brandings, :email_footer_text, :text
    add_column :organization_brandings, :custom_from_address, :string
    add_column :organization_brandings, :custom_email_domain, :string
    add_column :organization_brandings, :email_domain_verified, :boolean, default: false, null: false
    add_column :organization_brandings, :report_footer_text, :string
    add_column :organization_brandings, :show_powered_by, :boolean, default: true, null: false
    add_column :organization_brandings, :support_email, :string
  end
end
