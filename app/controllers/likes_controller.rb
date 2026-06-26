class LikesController < ApplicationController
  def create
    good_deed = GoodDeed.find(params[:good_deed_id])
    current_user.likes.create(good_deed: good_deed)
    redirect_back fallback_location: all_good_deeds_path
  end

  def destroy
    like = current_user.likes.find(params[:id])
    like.destroy
    redirect_back fallback_location: all_good_deeds_path
  end
end
