class AddTrackingTokenToApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :applications, :tracking_token, :string
    add_index :applications, :tracking_token, unique: true
  end
end
