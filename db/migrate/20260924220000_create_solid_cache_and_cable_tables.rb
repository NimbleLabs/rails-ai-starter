# Brings Solid Cache and Solid Cable into the primary database.
#
# The Rails 8 default splits cache, queue and cable into their own databases,
# each with its own schema file loaded by `db:prepare` rather than by
# `db:migrate`. That is a reasonable default at scale and a foot-gun at ours:
# the extra databases have to be created out of band (which a managed Postgres
# user often lacks permission to do), the schema files are invisible to
# `db:migrate`, and when the tables are missing the app still boots — so
# `/up` stays green while every page that touches the cache returns 500.
#
# One database instead. These tables now live in db/schema.rb like everything
# else, `bin/rails db:migrate` creates them, and there is nothing else to
# remember. solid_queue's tables were already here; this makes cache and cable
# consistent with them.
#
# The trade-off, stated: cache and queue churn now shares the primary database
# and its backups. At this size that is not worth a second database, and
# `bin/rails cache:clear` still empties the cache in one statement.
class CreateSolidCacheAndCableTables < ActiveRecord::Migration[8.1]
  def change
    # if_not_exists: an environment that already loaded db/cache_schema.rb
    # through the old multi-database setup must not fail here.
    create_table :solid_cache_entries, if_not_exists: true do |t|
      t.binary   :key, limit: 1024, null: false
      t.binary   :value, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.integer  :key_hash, limit: 8, null: false
      t.integer  :byte_size, limit: 4, null: false

      t.index :byte_size, name: "index_solid_cache_entries_on_byte_size"
      t.index %i[key_hash byte_size], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
      t.index :key_hash, unique: true, name: "index_solid_cache_entries_on_key_hash"
    end

    create_table :solid_cable_messages, if_not_exists: true do |t|
      t.binary   :channel, limit: 1024, null: false
      t.binary   :payload, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.integer  :channel_hash, limit: 8, null: false

      t.index :channel, name: "index_solid_cable_messages_on_channel"
      t.index :channel_hash, name: "index_solid_cable_messages_on_channel_hash"
      t.index :created_at, name: "index_solid_cable_messages_on_created_at"
    end
  end
end
