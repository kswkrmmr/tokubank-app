class RewardsController < ApplicationController
  def index
    @available_points = current_user.available_points
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

  def redeem
    reward = current_user.rewards.find_by(id: params[:id])

    if reward.nil?
      redirect_to rewards_path, status: :see_other, danger: t("reward.redeem.unauthorized")
      return
    end

    case redeem_reward(reward)
    when :redeemed
      redirect_to rewards_path, status: :see_other,
        success: t("reward.redeem.success", name: reward.name)
    when :already_redeemed
      redirect_to rewards_path, status: :see_other, danger: t("reward.redeem.already_redeemed")
    when :insufficient
      redirect_to rewards_path, status: :see_other, danger: t("reward.redeem.insufficient")
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

  # ユーザーの行をロックしてから残高を確認する。
  #
  # ロックが無いと、連打や複数のご褒美を同時に叶える操作で残高を超えて
  # 消費できてしまう（いいねの二重送信と同じ構図だが、こちらはポイントが
  # 二重に引かれるため実害がある）。
  def redeem_reward(reward)
    current_user.with_lock do
      reward.reload
      return :already_redeemed if reward.redeemed?
      return :insufficient if current_user.available_points < reward.cost

      reward.update!(redeemed_at: Time.current)
      :redeemed
    end
  end

  def reward_params
    params.require(:reward).permit(:name, :cost)
  end
end
