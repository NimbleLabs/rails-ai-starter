class CreateCreditCards < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_cards do |t|
      t.string :brand
      t.string :country
      t.integer :exp_month
      t.integer :exp_year
      t.string :last4
      t.string :stripe_id
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
