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

  test "header links to the rewards page" do
    log_in_as(@user)
    get rewards_path

    assert_select "header a[href=?]", rewards_path, text: "ご褒美"
  end
end
