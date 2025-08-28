# == Schema Information
#
# Table name: email_templates
#
#  id         :bigint           not null, primary key
#  subject    :string
#  body       :text
#  send_group :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class EmailTemplate < ApplicationRecord
  extend FriendlyId
  friendly_id :subject, use: [:slugged, :finders]


  def already_sent?(user_or_contact)
    Ahoy::Message.where(user_type: user_or_contact.class.name, user_id: user_or_contact.id, subject: subject).first.present?
  end
end
