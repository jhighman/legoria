class RenameChangesColumnInAuditLogs < ActiveRecord::Migration[8.0]
  def change
    rename_column :audit_logs, :changes, :recorded_changes
  end
end
