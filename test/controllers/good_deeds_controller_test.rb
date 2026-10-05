require "test_helper"

class GoodDeedsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_good_deed_path
    assert_response :redirect
  end

  test "should get index" do
    get good_deeds_path
    assert_response :redirect
  end

  test "today points are counted in Asia/Tokyo even before 9:00 JST" do
    user = users(:one)
    user.good_deeds.create!(content: "朝の徳1", performed_on: Date.new(2026, 9, 11), points: 3)
    user.good_deeds.create!(content: "朝の徳2", performed_on: Date.new(2026, 9, 11), points: 4)

    # 2026-09-11 08:00 JST = 2026-09-10 23:00 UTC
    travel_to Time.zone.local(2026, 9, 11, 8, 0) do
      log_in_as(user)
      get good_deeds_path
    end

    assert_response :success
    assert_select "h2", text: "7 pt"
  end

  test "pagination does not duplicate or skip deeds sharing the same date" do
    user = users(:one)
    25.times { |i| user.good_deeds.create!(content: "同日の徳#{i}", performed_on: Date.new(2026, 5, 3), points: 1) }
    expected = user.good_deeds.pluck(:content)

    log_in_as(user)
    contents = [ 1, 2 ].flat_map do |page|
      get good_deeds_path(page: page)
      css_select(".card-body strong").map(&:text)
    end

    assert_equal expected.size, contents.size
    assert_equal expected.sort, contents.sort
  end

  test "index renders each deed with a delete button and without the author" do
    user = users(:one)
    deed = user.good_deeds.create!(content: "自分の徳", performed_on: Date.new(2026, 5, 3), points: 2)

    log_in_as(user)
    get good_deeds_path

    assert_response :success
    assert_select "h5", text: "合計徳ポイント"
    assert_select ".card-body strong", text: "自分の徳"
    assert_select "form[action=?]", good_deed_path(deed)
    assert_select ".card-body div", text: /by/, count: 0
  end

  test "all renders deeds from other users with the author and a like button" do
    other = users(:two)
    deed = other.good_deeds.create!(content: "他人の徳", performed_on: Date.new(2026, 5, 3), points: 3)

    log_in_as(users(:one))
    get all_good_deeds_path

    assert_response :success
    assert_select "title", text: /みんなの徳/
    assert_select "h5", text: "みんなの合計徳ポイント"
    assert_select ".card-body strong", text: "他人の徳"
    assert_select ".card-body div", text: /by #{other.name}/
    assert_select "#like_button_#{deed.id}"
  end

  test "destroying own deed redirects with a success flash" do
    user = users(:one)
    deed = user.good_deeds.create!(content: "消す徳", performed_on: Date.new(2026, 5, 3), points: 1)

    log_in_as(user)
    assert_difference "GoodDeed.count", -1 do
      delete good_deed_path(deed)
    end

    assert_redirected_to good_deeds_path
    follow_redirect!
    assert_select ".alert.alert-success", text: /削除しました/
  end

  test "cannot destroy another user's deed" do
    deed = good_deeds(:two)

    log_in_as(users(:one))
    assert_no_difference "GoodDeed.count" do
      delete good_deed_path(deed)
    end

    assert_redirected_to good_deeds_path
    follow_redirect!
    assert_select ".alert.alert-danger", text: /権限がありません/
  end

  test "points summary is shown even on a page beyond the last one" do
    log_in_as(users(:one))
    get good_deeds_path(page: 99)

    assert_response :success
    assert_select "h5", text: "合計徳ポイント"
    assert_select ".card-body strong", count: 0
    assert_select "div", text: "まだ徳を積んでいないようです"
  end

  # ヘッダーのリンクの行き先はブラウザを起動しなくても確認できる。
  # 以前は system テストで実際にクリックして遷移を見ていたが、
  # クリックが稀に失われて CI が不安定になるため、この層に移した。
  test "header links point to the right pages when logged in" do
    log_in_as(users(:one))

    [ good_deeds_path, all_good_deeds_path, new_good_deed_path ].each do |path|
      get path

      assert_response :success
      assert_select "header a[href=?]", new_good_deed_path, text: "徳を積む"
      assert_select "header a[href=?]", good_deeds_path, text: "積み重ねた徳"
      assert_select "header a[href=?]", all_good_deeds_path, text: "みんなの徳"
      assert_select "header form[action=?]", logout_path
    end
  end

  test "header shows the login links when logged out" do
    get root_path

    assert_response :success
    assert_select "header a[href=?]", login_path, text: "ログイン"
    assert_select "header a[href=?]", new_user_path, text: "新規登録"
    assert_select "header a[href=?]", good_deeds_path, count: 0
  end

  # config.i18n.raise_on_missing_translations が有効なので、
  # 各画面を描画するだけで未定義の翻訳キーを検知できる
  test "main pages render without missing translations" do
    [ root_path, login_path, new_user_path ].each do |path|
      get path
      assert_response :success, "#{path} が描画できない"
    end

    log_in_as(users(:one))

    [ good_deeds_path, all_good_deeds_path, new_good_deed_path ].each do |path|
      get path
      assert_response :success, "#{path} が描画できない"
    end
  end
end
