class AddEncryptedFieldsToCandidates < ActiveRecord::Migration[8.0]
  def change
    add_column :candidates, :encrypted_email, :string
    add_column :candidates, :encrypted_email_iv, :string
    add_column :candidates, :encrypted_phone, :string
    add_column :candidates, :encrypted_phone_iv, :string
    add_column :candidates, :encrypted_ssn, :string
    add_column :candidates, :encrypted_ssn_iv, :string
  end
end
