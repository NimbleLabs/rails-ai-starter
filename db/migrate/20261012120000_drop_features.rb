# The old in-app backlog. Apps made from this starter take their work from NimbleHQ tasks instead.
class DropFeatures < ActiveRecord::Migration[8.1]
  def change
    drop_table :features do |t|
      t.text :acceptance_criteria
      t.string :area
      t.datetime :completed_at
      t.text :description
      t.text :implementation_notes
      t.text :plan
      t.integer :position
      t.integer :priority
      t.string :slug, index: true
      t.datetime :started_at
      t.integer :status
      t.string :title
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
