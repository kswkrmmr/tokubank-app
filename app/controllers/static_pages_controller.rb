class StaticPagesController < ApplicationController
  skip_before_action :require_login, only: %i[ top ]

  def top
    redirect_to good_deeds_path if logged_in?
  end
end
