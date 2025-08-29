json.extract! article, :id, :title, :description, :author, :category, :published, :featured, :published_at, :created_at, :updated_at
json.url article_url(article, format: :json)
