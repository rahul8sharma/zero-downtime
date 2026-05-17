class AddUniqueIndexToIncidents < ActiveRecord::Migration[7.1]
  def change
    # Add composite index for faster duplicate detection
    # This helps prevent creating duplicate incidents for the same error
    add_index :incidents,
              [:project_id, :source, :http_path, :http_status, :status],
              name: 'index_incidents_on_error_signature',
              if_not_exists: true

    # Add index on last_synced_at for cleanup queries
    add_index :incidents, :last_synced_at, if_not_exists: true
  end
end
