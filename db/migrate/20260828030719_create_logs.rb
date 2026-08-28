class CreateLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :logs do |t|
      t.integer  :level,        null: false, default: 2      # info: 0, warn: 1, error: 2, fatal: 3
      t.string   :source,       null: false, default: "web"  # web | job | mobile | console | app
      t.text     :message,      null: false
      t.string   :error_class
      t.text     :backtrace
      t.jsonb    :context,      null: false, default: {}
      t.string   :fingerprint,  null: false
      t.integer  :occurrences,  null: false, default: 1
      t.datetime :last_seen_at, null: false
      t.datetime :resolved_at
      t.datetime :notified_at
      t.references :user, foreign_key: true, null: true
      t.string   :request_id
      t.string   :path

      t.timestamps
    end

    add_index :logs, [ :fingerprint, :resolved_at ]
    add_index :logs, [ :level, :last_seen_at ]
    add_index :logs, :last_seen_at
    add_index :logs, :resolved_at
  end
end
