# == Schema Information
#
# Table name: articles
#
#  id           :bigint           not null, primary key
#  author       :string
#  category     :string
#  description  :string
#  featured     :boolean
#  published    :boolean
#  published_at :datetime
#  slug         :string
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_articles_on_slug  (slug)
#
class Article < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [:slugged, :finders]
  has_rich_text :content
  has_one_attached :featured_image
end
