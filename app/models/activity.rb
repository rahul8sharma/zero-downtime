class Activity < ApplicationRecord
  belongs_to :project, optional: true

  def self.log(action:, project: nil, details: nil)
    create(
      action: action,
      project: project,
      details: details
    )
  end
end
