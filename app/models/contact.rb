# == Schema Information
#
# Table name: contacts
#
#  id              :bigint           not null, primary key
#  name            :string
#  email           :string
#  phone           :string
#  company_name    :string
#  budget_range    :string
#  message         :text
#  slug            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :integer
#  biggest_problem :text
#  source          :string
#
class Contact < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]
  has_subscriptions

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  # validates :message, presence: true

  belongs_to :company, optional: true
  has_many :messages, class_name: "Ahoy::Message", as: :user

  def first_name
    name.split[1]
  end

  def received_first_outreach_email?
    messages.exists?(['subject ILIKE ?', '%Are You Using AI%'])
  end
end
