json.extract! contact, :id, :name, :email, :phone, :company, :budget_range, :message, :created_at, :updated_at
json.url contact_url(contact, format: :json)
