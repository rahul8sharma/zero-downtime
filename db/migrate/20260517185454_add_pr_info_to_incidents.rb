class AddPrInfoToIncidents < ActiveRecord::Migration[7.1]
  def change
    add_column :incidents, :pr_url, :string
    add_column :incidents, :pr_number, :integer
    add_column :incidents, :pr_status, :string
    add_column :incidents, :pr_created_at, :datetime
    add_column :incidents, :branch_name, :string
    add_column :incidents, :fix_description, :text
  end
end
