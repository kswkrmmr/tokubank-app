class RewardsController < ApplicationController
  def index
    @pending_rewards = current_user.rewards.pending.order(cost: :asc, id: :asc)
    @redeemed_rewards = current_user.rewards.redeemed.order(redeemed_at: :desc, id: :desc)
  end

  def new
    @reward = Reward.new
  end

  def create
    @reward = current_user.rewards.build(reward_params)

    if @reward.save
      redirect_to rewards_path, success: t("reward.create.success")
    else
      flash.now[:danger] = t("reward.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reward = current_user.rewards.find_by(id: params[:id])

    if reward.nil?
      redirect_to rewards_path, status: :see_other, danger: t("reward.destroy.unauthorized")
    elsif reward.redeemed?
      # 叶えた記録は残高の根拠になるため消させない
      redirect_to rewards_path, status: :see_other, danger: t("reward.destroy.redeemed")
    else
      reward.destroy
      redirect_to rewards_path, status: :see_other, success: t("reward.destroy.success")
    end
  end

  private

  def reward_params
    params.require(:reward).permit(:name, :cost)
  end
end
