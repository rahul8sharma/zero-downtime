class CreateIncidents < ActiveRecord::Migration[7.1]
  def change
    create_table :incidents do |t|
      t.string :title
      t.string :severity
      t.string :status
      t.text :error_message
      t.text :stack_trace
      t.string :service
      t.string :source
      t.string :datadog_id
      t.references :project, null: false, foreign_key: true
      t.datetime :last_synced_at

      t.timestamps
    end
  end
end
