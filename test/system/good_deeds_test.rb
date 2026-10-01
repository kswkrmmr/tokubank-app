require "application_system_test_case"

class GoodDeedsTest < ApplicationSystemTestCase
  setup { @user = users(:one) }

  test "registers a good deed and sees it in the list" do
    log_in_as(@user)

    visit new_good_deed_path
    assert_selector "h1", text: "あなたの善行教えてください"
    wait_for_turbo

    fill_in_and_submit("登録",
      good_deed_content: "電車で席を譲った",
      good_deed_performed_on: Date.new(2026, 5, 3),
      good_deed_points: "5")

    assert_text "ありがとうございます"
    assert_text "電車で席を譲った"
    assert_text "5 pt"
  end

  test "shows validation errors when the form is incomplete" do
    log_in_as(@user)
    visit new_good_deed_path
    wait_for_turbo

    click_button "登録"

    assert_text "登録に失敗しました"
    assert_selector "#error_explanation"
  end

  test "deletes a deed after accepting the confirmation dialog" do
    @user.good_deeds.create!(content: "消す徳", performed_on: Date.new(2026, 5, 3), points: 1)
    log_in_as(@user)
    wait_for_turbo

    accept_confirm do
      find(".card-body", text: "消す徳").click_button "削除"
    end

    assert_text "削除しました"
    assert_no_text "消す徳"
  end

  test "keeps the deed when the confirmation dialog is dismissed" do
    @user.good_deeds.create!(content: "消す徳", performed_on: Date.new(2026, 5, 3), points: 1)
    log_in_as(@user)
    wait_for_turbo

    dismiss_confirm do
      find(".card-body", text: "消す徳").click_button "削除"
    end

    assert_text "消す徳"
    assert_no_text "削除しました"
  end

  test "navigates between the list pages from the header" do
    log_in_as(@user)

    click_on "みんなの徳"
    assert_selector "h5", exact_text: "みんなの合計徳ポイント"
    # アサーションがプレビューに対して通ることがあるため、
    # 次のクリックの前に本来の描画への差し替えを待つ
    wait_for_turbo

    click_on "積み重ねた徳"
    # 「みんなの合計徳ポイント」の部分一致で通ってしまわないよう完全一致で見る
    assert_selector "h5", exact_text: "合計徳ポイント"
  end
end
