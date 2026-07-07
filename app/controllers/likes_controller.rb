class LikesController < ApplicationController
  def create
    @good_deed = GoodDeed.find(params[:good_deed_id])
    @like = current_user.likes.create(good_deed: @good_deed)
    @good_deed.reload

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: all_good_deeds_path }
    end
  end

  def destroy
    @like = current_user.likes.find(params[:id])
    @good_deed = @like.good_deed
    @like.destroy
    @good_deed.reload

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: all_good_deeds_path }
    end
  end
end
