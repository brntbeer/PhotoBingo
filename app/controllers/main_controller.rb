class MainController < ApplicationController
  before_filter :authenticate_user!
  def menu

  end
end