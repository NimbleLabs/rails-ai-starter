class CreateArticles < ActiveRecord::Migration[7.2]
  def change
    create_table :articles do |t|
      t.string :title
      t.string :description
      t.string :author
      t.string :category
      t.boolean :published
      t.boolean :featured
      t.datetime :published_at
      t.string :slug, index: true
      t.timestamps
    end
  end
end
