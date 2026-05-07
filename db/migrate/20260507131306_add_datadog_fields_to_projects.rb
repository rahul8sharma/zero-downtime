class AddDatadogFieldsToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :datadog_api_key, :string
    add_column :projects, :datadog_app_key, :string
    add_column :projects, :datadog_site, :string
  end
end
