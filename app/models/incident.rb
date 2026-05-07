class Incident < ApplicationRecord
  belongs_to :project

  validates :title, presence: true
  validates :datadog_id, uniqueness: { scope: :project_id }, allow_nil: true

  scope :open, -> { where(status: 'open') }
  scope :recent, -> { order(created_at: :desc) }
end
