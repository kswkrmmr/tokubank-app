require "application_system_test_case"

class ContentSecurityPolicyTest < ApplicationSystemTestCase
  setup { @user = users(:one) }

  test "emits a nonce for Turbo to use" do
    visit login_path

    assert_selector "meta[name='csp-nonce']", visible: false
  end

  test "does not block the Google Fonts stylesheet" do
    visit login_path
    wait_for_turbo

    loaded = page.evaluate_script(<<~JS)
      Array.from(document.styleSheets).some(s => s.href && s.href.includes("fonts.googleapis.com"))
    JS

    assert loaded, "Google Fonts のスタイルシートが CSP で弾かれている"
  end

  test "does not block the bundled JavaScript" do
    visit login_path
    wait_for_turbo

    assert page.evaluate_script("typeof window.Turbo !== 'undefined'"),
      "Turbo が読み込まれていない"
    assert page.evaluate_script("typeof window.bootstrap !== 'undefined'"),
      "Bootstrap が読み込まれていない"
  end

  test "does not block the Turbo Stream update when liking" do
    deed = good_deeds(:two)
    log_in_as(@user)

    visit all_good_deeds_path
    wait_for_turbo
    record_csp_violations

    find("#like_button_#{deed.id} button").click
    assert_selector "#like_button_#{deed.id} button.btn-danger", text: "♥ 1"

    assert_empty csp_violations, "いいねの操作で CSP 違反が発生している"
  end

  # Bootstrap の collapse は style 属性を書き換えて開閉するため、
  # style-src-attr の設定が間違っているとここで落ちる
  test "does not block the collapsible navbar" do
    log_in_as(@user)
    page.driver.browser.manage.window.resize_to(500, 800)

    visit good_deeds_path
    wait_for_turbo
    record_csp_violations

    assert_no_selector ".navbar-collapse.show"
    find(".navbar-toggler").click
    assert_selector ".navbar-collapse.show"

    assert_empty csp_violations, "ナビの開閉で CSP 違反が発生している"
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
