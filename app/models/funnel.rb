# == Schema Information
#
# Table name: funnels
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  slug        :string
#  description :text
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_funnels_on_slug  (slug)
#
class Funnel < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  validates :name, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  def self.funnel_metrics(funnel_slug: nil, start_date: nil, end_date: nil)
    events = Ahoy::Event.where(name: "funnel_page_view")

    if funnel_slug.present?
      events = events.where("properties->>'funnel_slug' = ?", funnel_slug)
    end

    if start_date.present?
      events = events.where("time >= ?", start_date.to_date.beginning_of_day)
    end

    if end_date.present?
      events = events.where("time <= ?", end_date.to_date.end_of_day)
    end

    page_counts = events.group("properties->>'page_type'").count

    {
      lead_page: page_counts["lead_page"] || 0,
      book_call_page: page_counts["book_call_page"] || 0,
      order_page: page_counts["order_page"] || 0,
      order_completed_page: page_counts["order_completed_page"] || 0
    }
  end
end
