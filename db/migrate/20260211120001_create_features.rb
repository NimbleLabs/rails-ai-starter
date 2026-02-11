class CreateFeatures < ActiveRecord::Migration[8.0]
  def change
    create_table :features do |t|
      t.string :title
      t.references :user, null: false, foreign_key: true
      t.text :description
      t.integer :status
      t.integer :priority
      t.string :area
      t.text :plan
      t.text :implementation_notes
      t.text :acceptance_criteria
      t.datetime :started_at
      t.datetime :completed_at
      t.string :slug, index: true

      t.timestamps
    end
  end
end
