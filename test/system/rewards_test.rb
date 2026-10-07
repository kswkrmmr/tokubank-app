require "application_system_test_case"

class RewardsTest < ApplicationSystemTestCase
  setup { @user = users(:one) }

  test "registers a reward and redeems it" do
    @user.good_deeds.create!(content: "たくさん徳を積んだ", performed_on: Date.new(2026, 5, 3), points: 1_000)
    log_in_as(@user)

    visit new_reward_path
    wait_for_turbo
    fill_in_and_submit("登録", reward_name: "温泉に行く", reward_cost: "400")

    assert_text "ご褒美を登録しました"
    wait_for_turbo

    accept_confirm do
      find(".card-body", text: "温泉に行く").click_button "叶える"
    end

    assert_text "温泉に行く を叶えました"
    assert_text "に叶えました"
  end

  test "shows how many points are missing when the balance is short" do
    log_in_as(@user)

    visit rewards_path
    wait_for_turbo

    # fixture の映画を見る（500pt）は残高が足りない
    within find(".card-body", text: "映画を見る") do
      assert_no_button "叶える"
      assert_text "あと"
    end
  end
end
