require "test_helper"

class RewardsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  def valid_params(**overrides)
    { reward: { name: "沖縄旅行", cost: 5_000 }.merge(overrides) }
  end

  test "requires login" do
    get rewards_path
    assert_redirected_to login_path
  end

  test "index lists own pending and redeemed rewards" do
    log_in_as(@user)
    get rewards_path

    assert_response :success
    assert_select "strong", text: rewards(:pending_one).name
    assert_select "strong", text: rewards(:redeemed_one).name
  end

  test "index does not list other users' rewards" do
    log_in_as(@user)
    get rewards_path

    assert_select "strong", text: rewards(:other_user).name, count: 0
  end

  test "creates a reward" do
    log_in_as(@user)

    assert_difference "Reward.count", 1 do
      post rewards_path, params: valid_params
    end

    assert_redirected_to rewards_path
    assert_equal @user, Reward.last.user
    assert_nil Reward.last.redeemed_at
  end

  test "does not create a reward without a name" do
    log_in_as(@user)

    assert_no_difference "Reward.count" do
      post rewards_path, params: valid_params(name: "")
    end

    assert_response :unprocessable_entity
    assert_select "#error_explanation"
  end

  test "does not create a reward with a non positive cost" do
    log_in_as(@user)

    assert_no_difference "Reward.count" do
      post rewards_path, params: valid_params(cost: 0)
    end

    assert_response :unprocessable_entity
  end

  test "destroys a pending reward" do
    log_in_as(@user)

    assert_difference "Reward.count", -1 do
      delete reward_path(rewards(:pending_one))
    end

    assert_redirected_to rewards_path
    follow_redirect!
    assert_select ".alert.alert-success"
  end

  # 叶えた記録は残高の根拠になるため消させない
  test "cannot destroy a redeemed reward" do
    log_in_as(@user)

    assert_no_difference "Reward.count" do
      delete reward_path(rewards(:redeemed_one))
    end

    assert_redirected_to rewards_path
    follow_redirect!
    assert_select ".alert.alert-danger", text: /叶えたご褒美は削除できません/
  end

  test "cannot destroy another user's reward" do
    log_in_as(@user)

    assert_no_difference "Reward.count" do
      delete reward_path(rewards(:other_user))
    end

    assert_redirected_to rewards_path
    follow_redirect!
    assert_select ".alert.alert-danger"
  end

  def give_points(points)
    @user.good_deeds.create!(content: "徳", performed_on: Date.new(2026, 5, 3), points: points)
  end

  # fixture の users(:one) は徳 1pt に対して 300pt 消費済み（残高 -299）なので、
  # 欲しい残高から逆算して徳を積む
  def set_balance_to(points)
    give_points(points - @user.available_points)
  end

  test "redeems a reward and reduces the balance" do
    give_points(1_000)
    reward = rewards(:pending_one) # 500pt
    before = @user.available_points

    log_in_as(@user)
    patch redeem_reward_path(reward)

    assert_redirected_to rewards_path
    assert_not_nil reward.reload.redeemed_at
    assert_equal before - reward.cost, @user.reload.available_points

    follow_redirect!
    assert_select ".alert.alert-success", text: /映画を見る を叶えました/
  end

  test "does not redeem when the balance is short" do
    reward = rewards(:pending_one) # 500pt。残高は足りていない

    log_in_as(@user)
    patch redeem_reward_path(reward)

    assert_nil reward.reload.redeemed_at
    follow_redirect!
    assert_select ".alert.alert-danger", text: /徳ポイントが足りません/
  end

  # 連打してもポイントが二重に引かれないこと
  test "redeeming twice only consumes the points once" do
    give_points(1_000)
    reward = rewards(:pending_one)
    before = @user.available_points

    log_in_as(@user)
    patch redeem_reward_path(reward)
    redeemed_at = reward.reload.redeemed_at

    patch redeem_reward_path(reward)

    assert_equal redeemed_at, reward.reload.redeemed_at
    assert_equal before - reward.cost, @user.reload.available_points
    follow_redirect!
    assert_select ".alert.alert-danger", text: /すでに叶えています/
  end

  # 残高 600 で 500pt のご褒美を2つ叶えようとしても、2つ目は弾かれること
  test "cannot redeem more than the balance across rewards" do
    set_balance_to(600)
    second = @user.rewards.create!(name: "温泉に行く", cost: 500)

    log_in_as(@user)
    patch redeem_reward_path(rewards(:pending_one))
    patch redeem_reward_path(second)

    assert_not_nil rewards(:pending_one).reload.redeemed_at
    assert_nil second.reload.redeemed_at
    assert_operator @user.reload.available_points, :>=, 0
  end

  test "cannot redeem another user's reward" do
    log_in_as(@user)
    patch redeem_reward_path(rewards(:other_user))

    assert_nil rewards(:other_user).reload.redeemed_at
    follow_redirect!
    assert_select ".alert.alert-danger"
  end

  test "header links to the rewards page" do
    log_in_as(@user)
    get rewards_path

    assert_select "header a[href=?]", rewards_path, text: "ご褒美"
  end
end
