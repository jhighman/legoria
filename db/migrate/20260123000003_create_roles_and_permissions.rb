# frozen_string_literal: true

# SA-01: Identity & Access - RBAC tables
class CreateRolesAndPermissions < ActiveRecord::Migration[8.0]
  def change
    # Roles - organization-scoped
    create_table :roles do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :description
      t.boolean :system_role, default: false, null: false
      t.json :permissions, default: {}, null: false

      t.timestamps
    end

    add_index :roles, [:organization_id, :name], unique: true

    # Permissions - system-wide catalog
    create_table :permissions do |t|
      t.string :resource, null: false
      t.string :action, null: false
      t.string :description

      t.datetime :created_at, null: false
    end

    add_index :permissions, [:resource, :action], unique: true

    # Role-Permission join with conditions
    create_table :role_permissions do |t|
      t.references :role, null: false, foreign_key: true
      t.references :permission, null: false, foreign_key: true
      t.json :conditions

      t.datetime :created_at, null: false
    end

    add_index :role_permissions, [:role_id, :permission_id], unique: true

    # User-Role assignment
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.datetime :granted_at, null: false
      t.references :granted_by, foreign_key: { to_table: :users }

      t.datetime :created_at, null: false
    end

    add_index :user_roles, [:user_id, :role_id], unique: true
  end
end
