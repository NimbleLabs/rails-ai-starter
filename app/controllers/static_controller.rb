class StaticController < ApplicationController
  before_action :authenticate_user!, only: %i[ app admin react_app ]

  layout :get_layout

  def index
  end

  def dark
  end

  def simple
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

  def react_app
  end

  def get_layout
    return 'empty' if action_name == 'app' || action_name == 'admin' || action_name == 'react_app'
    'application'
  end
end
