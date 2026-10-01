require "test_helper"
require "timeout"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # 既定は 2 秒。CI では初回リクエストが eager_load を伴って遅くなるため、
  # 遷移の完了を待ちきれずに失敗することがあった。
  Capybara.default_max_wait_time = 10

  # フィクスチャのユーザーはいずれもパスワードが "password"。
  # 統合テストの log_in_as と違い、実際にログイン画面を操作する。
  def log_in_as(user, password: "password")
    visit login_path
    wait_for_turbo
    fill_in "email", with: user.email
    fill_in "password", with: password
    click_button "ログイン"

    assert_text "ログインしました"
    wait_for_turbo
  end

  # ページの読み込みと Turbo の初期化が終わるまで待つ。
  # 初期化前に button_to のボタンを押すと送信が飛ばないことがある。
  def wait_for_turbo
    Timeout.timeout(Capybara.default_max_wait_time) do
      until page.evaluate_script("document.readyState") == "complete" &&
            page.evaluate_script("typeof window.Turbo !== 'undefined'")
        sleep 0.05
      end
    end
  end

  # 以降の操作で CSP 違反が起きたら記録する。
  # 読み込み時点の違反は拾えないので、そちらは
  # スタイルシートや JS が実際に読み込まれたかで確認する。
  def record_csp_violations
    page.execute_script(<<~JS)
      window.__cspViolations = [];
      document.addEventListener("securitypolicyviolation", (event) => {
        window.__cspViolations.push(event.violatedDirective + " " + (event.blockedURI || event.sourceFile));
      });
    JS
  end

  def csp_violations
    page.evaluate_script("window.__cspViolations || []")
  end
end
