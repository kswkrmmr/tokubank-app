require "test_helper"

class RewardTest < ActiveSupport::TestCase
  def build_reward(**attrs)
    users(:one).rewards.build({ name: "沖縄旅行", cost: 5_000 }.merge(attrs))
  end

  test "valid reward" do
    assert build_reward.valid?
  end

  test "name is required" do
    assert_not build_reward(name: nil).valid?
    assert_not build_reward(name: "").valid?
  end

  test "name has a maximum length" do
    assert build_reward(name: "あ" * Reward::MAX_NAME_LENGTH).valid?
    assert_not build_reward(name: "あ" * (Reward::MAX_NAME_LENGTH + 1)).valid?
  end

  test "cost must be a positive integer" do
    assert_not build_reward(cost: nil).valid?
    assert_not build_reward(cost: 0).valid?
    assert_not build_reward(cost: -1).valid?
    assert_not build_reward(cost: "abc").valid?
  end

  test "cost has an upper bound so it cannot overflow the integer column" do
    assert build_reward(cost: Reward::MAX_COST).valid?
    assert_not build_reward(cost: Reward::MAX_COST + 1).valid?
    assert_not build_reward(cost: 2_147_483_648).valid?
  end

  test "user is required" do
    assert_not Reward.new(name: "沖縄旅行", cost: 5_000).valid?
  end

  test "redeemed? tells whether it has been redeemed" do
    assert_not rewards(:pending_one).redeemed?
    assert rewards(:redeemed_one).redeemed?
  end

  test "scopes split pending and redeemed" do
    assert_includes Reward.pending, rewards(:pending_one)
    assert_not_includes Reward.pending, rewards(:redeemed_one)

    assert_includes Reward.redeemed, rewards(:redeemed_one)
    assert_not_includes Reward.redeemed, rewards(:pending_one)
  end

  test "destroying a user destroys their rewards" do
    assert_difference "Reward.count", -users(:one).rewards.count do
      users(:one).destroy
    end
  end
end
