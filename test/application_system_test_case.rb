require "test_helper"

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
  end
end
