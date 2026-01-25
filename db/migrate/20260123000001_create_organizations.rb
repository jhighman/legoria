# frozen_string_literal: true

# SA-02: Organization Management - Core tenant model
# All other tables reference organization_id for multi-tenancy
class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.string :domain
      t.string :logo_url
      t.string :timezone, default: "UTC", null: false
      t.string :default_currency, default: "USD", null: false
      t.string :default_locale, default: "en", null: false
      t.json :settings, default: {}, null: false
      t.string :billing_email
      t.string :plan, default: "trial", null: false
      t.datetime :trial_ends_at
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :organizations, :subdomain, unique: true
    add_index :organizations, :domain, unique: true, where: "domain IS NOT NULL"
    add_index :organizations, :discarded_at
  end
end
