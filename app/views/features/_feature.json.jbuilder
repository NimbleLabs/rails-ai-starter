json.extract! feature, :id, :slug, :title, :user_id, :description, :status, :priority, :area, :plan, :implementation_notes, :acceptance_criteria, :position, :started_at, :completed_at, :created_at, :updated_at
json.user feature.user, :id, :name, :email if feature.user
json.url feature_url(feature, format: :json)
