class GoodDeedsController < ApplicationController
  before_action :require_login

  def index
    deeds = current_user.good_deeds

    @good_deeds = deeds.order(performed_on: :desc).page(params[:page]).per(20)
    @total_points = deeds.sum(:points)
    @today_points = deeds.where(performed_on: Date.today).sum(:points)
  end

  def new
    @good_deed = GoodDeed.new
  end

  def create
    @good_deed = current_user.good_deeds.build(good_deed_params)

    if @good_deed.save
      redirect_to root_path, success: "ありがとうございます！良い行いをしましたね。"
    else
      flash.now[:danger] = "登録に失敗しました"
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    @good_deed = GoodDeed.find(params[:id])
    unless current_user.own?(@good_deed)
      redirect_to good_deeds_path, danger: "権限がありません"
      return
    end
    @good_deed.destroy
    redirect_to good_deeds_path, status: :see_other, success: "削除しました"
  end

  private

  def good_deed_params
    params.require(:good_deed).permit(:content, :performed_on, :points)
  end
end