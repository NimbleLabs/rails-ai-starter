class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin, only: %i[ index ]

  def index
    @users = User.all
  end

  def current
    if current_user.blank?
      render json: { message: "unauthorized" }, status: :forbidden
      return
    end

    render current_user
  end

end
