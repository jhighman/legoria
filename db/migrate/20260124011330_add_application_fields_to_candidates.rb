class AddApplicationFieldsToCandidates < ActiveRecord::Migration[8.0]
  def change
    add_column :candidates, :current_company, :string
    add_column :candidates, :current_title, :string
    add_column :candidates, :cover_letter, :text
    add_column :candidates, :source, :string
  end
end
