# frozen_string_literal: true

# JSON sign-in for mobile + other API clients.
#
# POST /api/v1/sessions
#   body: { "email": "x@y.com", "password": "..." }
#   200:  { "user": { ... }, "token": "<auth_token>" }
#   401:  { "error": "Invalid email or password" }
#
# DELETE /api/v1/sessions   (token required)
#   200:  { "ok": true }
#   Rotates the user's auth_token so the old token is invalidated.
class Api::V1::SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_with_token, only: :destroy

  def create
    user = User.find_by(email: params[:email].to_s.downcase.strip)

    if user&.valid_password?(params[:password])
      render json: { user: user_payload(user), token: user.auth_token }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def destroy
    current_user.regenerate_auth_token
    render json: { ok: true }, status: :ok
  end

  private

  def user_payload(user)
    {
      id: user.id,
      email: user.email,
      name: user.respond_to?(:name) ? user.name : nil
    }
  end
end
