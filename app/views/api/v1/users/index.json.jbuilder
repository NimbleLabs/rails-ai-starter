json.array! @users do |user|
  json.id user.id
  json.email user.email
  json.sign_in_count user.sign_in_count
  json.current_sign_in_at user.current_sign_in_at
  json.last_sign_in_at user.last_sign_in_at
  json.current_sign_in_ip user.current_sign_in_ip
  json.last_sign_in_ip user.last_sign_in_ip
  json.name user.name
  json.slug user.slug
  json.created_at user.created_at
  json.updated_at user.updated_at
end
