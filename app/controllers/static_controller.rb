class StaticController < ApplicationController
  before_action :authenticate_user!, only: %i[ app admin ]

  layout :get_layout

  def index
  end

  def about
  end

  def privacy
  end

  def terms
  end

  def app
  end

  def admin
  end

  def get_layout
    return 'empty' if action_name == 'app' || action_name == 'admin'
    'application'
  end
end
