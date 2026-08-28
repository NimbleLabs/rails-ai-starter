class AddOmniauthToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :avatar_url, :string

    # One identity per provider account. Unique so two local users can never
    # both claim the same Google account.
    add_index :users, [ :provider, :uid ], unique: true, where: "provider IS NOT NULL AND uid IS NOT NULL"
  end
end
