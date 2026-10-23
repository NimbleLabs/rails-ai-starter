# OAuth 2.1 for MCP clients (see config/initializers/doorkeeper.rb). New tables
# only, so it is safe to run against live data.
class CreateDoorkeeperTables < ActiveRecord::Migration[8.1]
  def change
    # One row per MCP client, created by dynamic client registration
    # (OauthClientRegistrationsController). Public clients have no secret.
    create_table :oauth_applications do |t|
      t.string  :name,         null: false
      t.string  :uid,          null: false
      t.string  :secret
      t.text    :redirect_uri, null: false
      t.string  :scopes,       null: false, default: ""
      t.boolean :confidential, null: false, default: true
      t.timestamps
    end
    add_index :oauth_applications, :uid, unique: true

    create_table :oauth_access_grants do |t|
      t.references :resource_owner, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :application,    null: false, foreign_key: { to_table: :oauth_applications, on_delete: :cascade }
      t.string   :token,             null: false
      t.integer  :expires_in,        null: false
      t.text     :redirect_uri,      null: false
      t.string   :scopes,            null: false, default: ""
      t.string   :code_challenge
      t.string   :code_challenge_method
      t.datetime :created_at,        null: false
      t.datetime :revoked_at
    end
    add_index :oauth_access_grants, :token, unique: true

    create_table :oauth_access_tokens do |t|
      t.references :resource_owner, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :application,    null: false, foreign_key: { to_table: :oauth_applications, on_delete: :cascade }
      t.string   :token,             null: false
      t.string   :refresh_token
      t.integer  :expires_in
      t.string   :scopes
      t.datetime :created_at,        null: false
      t.datetime :revoked_at
      # With this column Doorkeeper revokes a refresh token only once the token
      # that replaced it is used, so a client that lost a response can retry.
      t.string   :previous_refresh_token, null: false, default: ""
    end
    add_index :oauth_access_tokens, :token, unique: true
    add_index :oauth_access_tokens, :refresh_token, unique: true
  end
end
