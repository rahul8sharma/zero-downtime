class Project < ApplicationRecord
  validates :name, presence: true

  has_many :activities, dependent: :destroy
  has_many :incidents, dependent: :destroy
end
