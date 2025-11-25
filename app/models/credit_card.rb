# == Schema Information
#
# Table name: credit_cards
#
#  id         :bigint           not null, primary key
#  brand      :string
#  country    :string
#  exp_month  :integer
#  exp_year   :integer
#  last4      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  stripe_id  :string
#  user_id    :bigint           not null
#
# Indexes
#
#  index_credit_cards_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class CreditCard < ApplicationRecord
  belongs_to :user
end
