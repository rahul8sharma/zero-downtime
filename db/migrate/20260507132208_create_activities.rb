class CreateActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :activities do |t|
      t.string :action
      t.references :project, null: false, foreign_key: true
      t.text :details

      t.timestamps
    end
  end
end
