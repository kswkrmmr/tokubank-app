class GoodDeedsController < ApplicationController
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
      redirect_to root_path, success: t('good_deed.create.success')
    else
      flash.now[:danger] = t('good_deed.create.failure')
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    @good_deed = GoodDeed.find(params[:id])
    unless current_user.own?(@good_deed)
      redirect_to good_deeds_path, danger: t('good_deed.destroy.unauthorized')
      return
    end
    @good_deed.destroy
    redirect_to good_deeds_path, status: :see_other, success: t('good_deed.destroy.success')
  end

  private

  def good_deed_params
    params.require(:good_deed).permit(:content, :performed_on, :points)
  end
end