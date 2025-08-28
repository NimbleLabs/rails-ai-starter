class CreateContacts < ActiveRecord::Migration[7.2]
  def change
    create_table :contacts do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :company
      t.string :budget_range
      t.text :message
      t.string :slug, index: true

      t.timestamps
    end
  end
end
