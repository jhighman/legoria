# frozen_string_literal: true

# Phase 4: Offer letter templates with variable substitution
class CreateOfferTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :offer_templates do |t|
      t.references :organization, null: false, foreign_key: true

      # Template info
      t.string :name, null: false
      t.text :description
      t.string :template_type, null: false, default: "standard" # standard, executive, contractor, intern

      # Template content (supports Liquid/ERB variables)
      t.text :subject_line
      t.text :body, null: false
      t.text :footer

      # Available variables (JSON array of variable names)
      t.json :available_variables

      # Status
      t.boolean :active, null: false, default: true
      t.boolean :is_default, null: false, default: false

      t.timestamps
    end

    add_index :offer_templates, [:organization_id, :active]
    add_index :offer_templates, [:organization_id, :template_type]
    add_index :offer_templates, [:organization_id, :is_default]
  end
end
