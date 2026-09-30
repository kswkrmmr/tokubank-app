require "application_system_test_case"

class LikesTest < ApplicationSystemTestCase
  test "likes and unlikes another user's deed without reloading the page" do
    deed = good_deeds(:two) # users(:two) の徳
    log_in_as(users(:one))

    visit all_good_deeds_path

    # ページ全体が再読み込みされたら消える目印。
    # Turbo Stream で差し替わっているかどうかをこれで判定する。
    page.execute_script("window.__notReloaded = true")

    within "#like_button_#{deed.id}" do
      assert_selector "button.btn-outline-danger", text: "♡ 0"
      find("button").click
    end

    assert_selector "#like_button_#{deed.id} button.btn-danger", text: "♥ 1"
    assert page.evaluate_script("window.__notReloaded"),
      "ページ全体が再読み込みされている（Turbo Stream で差し替わっていない）"

    within "#like_button_#{deed.id}" do
      find("button").click
    end

    assert_selector "#like_button_#{deed.id} button.btn-outline-danger", text: "♡ 0"
    assert page.evaluate_script("window.__notReloaded"),
      "ページ全体が再読み込みされている（Turbo Stream で差し替わっていない）"
  end
end
