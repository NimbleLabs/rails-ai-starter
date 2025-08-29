# == Schema Information
#
# Table name: articles
#
#  id           :bigint           not null, primary key
#  title        :string
#  description  :string
#  author       :string
#  category     :string
#  published    :boolean
#  featured     :boolean
#  published_at :datetime
#  slug         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Article < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [:slugged, :finders]
  has_rich_text :content
  has_one_attached :featured_image
end
