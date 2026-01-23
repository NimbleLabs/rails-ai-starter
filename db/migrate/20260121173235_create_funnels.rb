class CreateFunnels < ActiveRecord::Migration[8.1]
  def change
    create_table :funnels do |t|
      t.string :name, null: false
      t.string :slug
      t.text :description
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :funnels, :slug
  end
end
