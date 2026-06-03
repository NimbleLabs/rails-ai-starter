# frozen_string_literal: true

# JSON sign-up for mobile + other API clients.
#
# POST /api/v1/registrations
#   body: { "email": "x@y.com", "password": "...", "name": "Optional" }
#   201:  { "user": { ... }, "token": "<auth_token>" }
#   422:  { "errors": { "email": ["has already been taken"], ... } }
class Api::V1::RegistrationsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    user = User.new(user_params)

    if user.save
      render json: { user: user_payload(user), token: user.auth_token }, status: :created
    else
      render json: { errors: user.errors.as_json }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    permitted = params.permit(:email, :password, :password_confirmation, :name)
    permitted[:email] = permitted[:email].to_s.downcase.strip
    permitted
  end

  def user_payload(user)
    {
      id: user.id,
      email: user.email,
      name: user.respond_to?(:name) ? user.name : nil
    }
  end
end
