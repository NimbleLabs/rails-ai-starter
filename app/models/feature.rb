class Feature < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [:slugged, :finders]
  belongs_to :user

  enum :status, { backlog: 0, planned: 1, in_progress: 2, completed: 3, cancelled: 4 }
  enum :priority, { low: 0, medium: 1, high: 2, critical: 3 }

  before_create :assign_position
  before_update :manage_position, if: :status_changed?

  scope :backlog_ordered, -> { where(status: :planned).order(position: :asc) }

  private

  def assign_position
    if planned?
      self.position ||= (Feature.where(status: :planned).maximum(:position) || 0) + 1
    end
  end

  def manage_position
    if planned? && position.nil?
      # Entering planned status — append to end
      self.position = (Feature.where(status: :planned).maximum(:position) || 0) + 1
    elsif !planned? && position.present?
      # Leaving planned status — clear position
      self.position = nil
    end
  end
end
