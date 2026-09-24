class LikesController < ApplicationController
  def create
    @good_deed = GoodDeed.find(params[:good_deed_id])
    @like = find_or_create_like(@good_deed)
    @good_deed.reload

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: all_good_deeds_path }
    end
  end

  def destroy
    @like = current_user.likes.find_by(id: params[:id])

    # 既に解除済み（二重送信・別タブからの操作）。現在の状態を返し直すだけにする。
    if @like.nil?
      redirect_back fallback_location: all_good_deeds_path, status: :see_other
      return
    end

    @good_deed = @like.good_deed
    @like.destroy
    @good_deed.reload

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: all_good_deeds_path }
    end
  end

  private

  # 既にいいね済みなら既存のレコードを返す。
  # 同時リクエストでユニークインデックスに当たった側も、既存のレコードを拾う。
  def find_or_create_like(good_deed)
    current_user.likes.find_or_create_by(good_deed: good_deed)
  rescue ActiveRecord::RecordNotUnique
    current_user.likes.find_by!(good_deed: good_deed)
  end
end
