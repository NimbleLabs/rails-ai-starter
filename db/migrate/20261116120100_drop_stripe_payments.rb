# The half-built Stripe payments (PaymentsController, CreditCard) were removed from the starter: no page used them
# and nothing confirmed a charge by webhook. A project that takes money should add Stripe Checkout and a webhook.
class DropStripePayments < ActiveRecord::Migration[8.1]
  def change
    drop_table :credit_cards do |t|
      t.string :brand
      t.string :country
      t.integer :exp_month
      t.integer :exp_year
      t.string :last4
      t.string :stripe_id
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    remove_column :users, :stripe_customer_id, :string
    remove_column :users, :stripe_subscription_id, :string
    remove_column :users, :payment_intent_id, :string
  end
end
