# frozen_string_literal: true

# SA-09: Compliance & Audit - Immutable audit log
# Required from Phase 1 for compliance
class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, foreign_key: true # Null for system actions
      t.string :action, null: false
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.json :metadata, default: {}, null: false
      t.json :changes, default: {}
      t.string :ip_address
      t.string :user_agent
      t.string :request_id

      # Immutable - only created_at
      t.datetime :created_at, null: false
    end

    add_index :audit_logs, [:organization_id, :created_at]
    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, [:organization_id, :action]
    add_index :audit_logs, :request_id
  end
end
