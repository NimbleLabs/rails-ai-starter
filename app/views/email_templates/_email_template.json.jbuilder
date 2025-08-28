json.extract! email_template, :id, :slug, :subject, :body, :send_group, :created_at, :updated_at
json.url email_template_url(email_template, format: :json)
