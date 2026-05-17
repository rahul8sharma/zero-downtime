class AddTraceInfoToIncidents < ActiveRecord::Migration[7.1]
  def change
    add_column :incidents, :trace_id, :string
    add_column :incidents, :span_id, :string
    add_column :incidents, :trace_url, :string
    add_column :incidents, :http_method, :string
    add_column :incidents, :http_path, :string
    add_column :incidents, :http_status, :integer
    add_column :incidents, :duration_ms, :float
  end
end
