require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "signs up and logs in with a differently cased email" do
    visit new_user_path
    wait_for_turbo

    fill_in_and_submit("登録",
      user_name: "テスト太郎",
      user_email: "Taro@Example.com",
      user_password: "password",
      user_password_confirmation: "password")

    assert_text "ユーザー登録が完了しました"

    # 登録時に大文字が含まれていても、入力の大小文字に関係なくログインできる
    visit login_path
    wait_for_turbo
    fill_in_and_submit("ログイン", email: "TARO@example.com", password: "password")

    assert_text "ログインしました"
    assert_text "まだ徳を積んでいないようです"
  end

  test "shows an error for a wrong password without leaving the form" do
    visit login_path
    wait_for_turbo

    fill_in_and_submit("ログイン", email: users(:one).email, password: "wrongpassword")

    assert_text "ログインに失敗しました"
    assert_button "ログイン"
  end

  test "logs out" do
    log_in_as(users(:one))

    click_button "ログアウト"

    assert_text "ログアウトしました"
    assert_link "ログイン"
  end

  test "redirects to the login page when not logged in" do
    visit good_deeds_path

    assert_text "ログインしてください"
    assert_button "ログイン"
  end
end
