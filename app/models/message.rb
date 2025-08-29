# == Schema Information
#
# Table name: messages
#
#  id            :bigint           not null, primary key
#  content       :text
#  input_tokens  :integer
#  output_tokens :integer
#  role          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  chat_id       :bigint           not null
#  model_id      :string
#  tool_call_id  :bigint
#
# Indexes
#
#  index_messages_on_chat_id       (chat_id)
#  index_messages_on_tool_call_id  (tool_call_id)
#
# Foreign Keys
#
#  fk_rails_...  (chat_id => chats.id)
#
class Message < ApplicationRecord
  acts_as_message
end
