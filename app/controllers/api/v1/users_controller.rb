class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin, only: %i[ index show]

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
    render json: @user
  end

  def current
    if current_user.blank?
      render json: { message: "unauthorized" }, status: :forbidden
      return
    end

    render current_user
  end

end
