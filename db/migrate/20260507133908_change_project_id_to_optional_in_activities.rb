class ChangeProjectIdToOptionalInActivities < ActiveRecord::Migration[7.1]
  def change
    change_column_null :activities, :project_id, true
  end
end
