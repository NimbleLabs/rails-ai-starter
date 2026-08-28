# == Schema Information
#
# Table name: contacts
#
#  id           :bigint           not null, primary key
#  budget_range :string
#  company      :string
#  email        :string
#  message      :text
#  name         :string
#  phone        :string
#  slug         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_contacts_on_slug  (slug)
#
class Contact < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]
  has_subscriptions

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  # validates :message, presence: true

  has_many :messages, class_name: "Ahoy::Message", as: :user

  after_create :on_after_create

  def first_name
    name.split[1]
  end

  def received_first_outreach_email?
    messages.exists?(['subject ILIKE ?', '%Are You Using AI%'])
  end

  def on_after_create
    #UserMailer.with(user: self).welcome_email.deliver_later(wait: 2.seconds)
    subscribe("Newsletter")
  end
end
