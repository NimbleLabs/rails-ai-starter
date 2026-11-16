# The marketing-funnel landing pages (/f/:slug/...) and their admin tabs were removed from the starter.
# Visits and events stay in Ahoy, so a project that wants a funnel can build one for how it actually converts.
class DropFunnels < ActiveRecord::Migration[8.1]
  def change
    drop_table :funnels do |t|
      t.string :name, null: false
      t.string :slug, index: true
      t.text :description
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
