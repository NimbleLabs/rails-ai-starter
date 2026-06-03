class Api::V1::UsersController < ApplicationController
  # `current` accepts the x-api-token header (token OR Devise session) so mobile
  # clients can hit it after signing in through Api::V1::SessionsController.
  before_action :authenticate_user_or_token, only: %i[current]
  before_action :authenticate_user!,         only: %i[index show]
  before_action :ensure_admin,               only: %i[index show]

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
  end

  def current
    render json: {
      user: {
        id: current_user.id,
        email: current_user.email,
        name: current_user.respond_to?(:name) ? current_user.name : nil
      }
    }
  end
end
