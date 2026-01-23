# == Schema Information
#
# Table name: chats
#
#  id         :bigint           not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  model_id   :bigint
#  user_id    :bigint           not null
#
# Indexes
#
#  index_chats_on_model_id  (model_id)
#  index_chats_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (model_id => models.id)
#  fk_rails_...  (user_id => users.id)
#
class Chat < ApplicationRecord
  acts_as_chat messages_foreign_key: :chat_id
  belongs_to :user
end
