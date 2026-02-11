class Feature < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [:slugged, :finders]
  belongs_to :user

  enum :status, { backlog: 0, planned: 1, in_progress: 2, completed: 3, cancelled: 4 }
  enum :priority, { low: 0, medium: 1, high: 2, critical: 3 }
end
