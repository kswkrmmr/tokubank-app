require "test_helper"
require "timeout"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # フィクスチャのユーザーはいずれもパスワードが "password"。
  # 統合テストの log_in_as と違い、実際にログイン画面を操作する。
  def log_in_as(user, password: "password")
    visit login_path
    fill_in "email", with: user.email
    fill_in "password", with: password
    click_button "ログイン"

    assert_text "ログインしました"
    wait_for_turbo
  end

  # Turbo の読み込みが終わる前に button_to のボタンを押すと、送信が
  # どこにも飛ばずに握り潰されることがある（リクエストがサーバに届かない）。
  # JS の挙動に依存する操作の前に呼ぶ。
  def wait_for_turbo
    Timeout.timeout(Capybara.default_max_wait_time) do
      until page.evaluate_script("document.readyState") == "complete" &&
            page.evaluate_script("typeof window.Turbo !== 'undefined'")
        sleep 0.05
      end
    end
  end
end
