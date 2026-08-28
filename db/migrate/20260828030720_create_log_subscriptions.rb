class CreateLogSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :log_subscriptions do |t|
      t.string   :name
      t.integer  :channel,          null: false, default: 0   # email: 0, slack: 1
      t.string   :destination,      null: false               # email address or Slack incoming-webhook URL
      t.integer  :min_level,        null: false, default: 2   # notify at or above this Log level (error)
      t.boolean  :active,           null: false, default: true
      t.integer  :throttle_minutes, null: false, default: 60  # min gap between re-notifications for the same log
      t.datetime :last_notified_at

      t.timestamps
    end

    add_index :log_subscriptions, :active
  end
end
