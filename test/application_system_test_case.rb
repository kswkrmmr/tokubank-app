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

    fill_in_and_submit("ログイン", email: user.email, password: password)

    assert_text "ログインしました"
    wait_for_turbo
  end

  # 入力した直後にページが差し替わり、値が消えた状態で送信されることがある
  # （CI の失敗時スクリーンショットで全フィールドが空になっていた）。
  # 値が残っていることを確認してから送信し、消えていれば入れ直す。
  def fill_in_and_submit(button, fields)
    mark_page

    2.times do |attempt|
      fields.each { |name, value| fill_in name.to_s, with: value }
      # date フィールドに Date を渡した場合も比較できるよう文字列に揃える
      break if fields.all? { |name, value| page.has_field?(name.to_s, with: value.to_s, wait: 1) }

      flunk <<~MSG if attempt == 1
        入力が保持されない。ページが差し替わった形跡: #{page_replaced? ? "あり" : "なし"}
        現在の URL: #{page.current_url}
      MSG
    end

    click_button button
  end

  # ページ全体が再読み込み・差し替えされたかを判定するための目印
  def mark_page
    page.execute_script("window.__pageMark = true")
  end

  def page_replaced?
    !page.evaluate_script("window.__pageMark")
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
