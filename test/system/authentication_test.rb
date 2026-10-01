require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "signs up and logs in with a differently cased email" do
    visit new_user_path
    wait_for_turbo

    fill_in "user_name", with: "テスト太郎"
    fill_in "user_email", with: "Taro@Example.com"
    fill_in "user_password", with: "password"
    fill_in "user_password_confirmation", with: "password"
    click_button "登録"

    assert_text "ユーザー登録が完了しました"

    # 登録時に大文字が含まれていても、入力の大小文字に関係なくログインできる
    visit login_path
    wait_for_turbo
    fill_in "email", with: "TARO@example.com"
    fill_in "password", with: "password"
    click_button "ログイン"

    assert_text "ログインしました"
    assert_text "まだ徳を積んでいないようです"
  end

  test "shows an error for a wrong password without leaving the form" do
    visit login_path
    wait_for_turbo

    fill_in "email", with: users(:one).email
    fill_in "password", with: "wrongpassword"
    click_button "ログイン"

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
