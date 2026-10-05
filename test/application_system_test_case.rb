require "test_helper"
require "timeout"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # 手元のコンテナ（Dockerfile.test）では Debian の chromium を使う。
  # CI は環境変数を設定しないため、従来どおり Selenium Manager に任せる。
  Selenium::WebDriver::Chrome.path = ENV["CHROME_BIN"] if ENV["CHROME_BIN"]
  Selenium::WebDriver::Chrome::Service.driver_path = ENV["CHROMEDRIVER_BIN"] if ENV["CHROMEDRIVER_BIN"]

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    # コンテナでは root で動くため sandbox を無効にする必要がある
    if ENV["CHROME_BIN"]
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
    end

    # 失敗時にブラウザのコンソールログを取得するために必要
    options.add_option("goog:loggingPrefs", { browser: "ALL" })

    # Chrome のパスワードマネージャがログインフォームを解析し、入力した値を
    # 消してしまうことがある（CI の失敗時に両方のフィールドが空になり、
    # コンソールに password 関連の DOM 警告が繰り返し記録されていた）。
    options.add_preference("credentials_enable_service", false)
    options.add_preference("profile.password_manager_enabled", false)
    options.add_preference("autofill.profile_enabled", false)
    options.add_argument("--disable-save-password-bubble")
  end

  # 失敗したときに原因を追えるよう、スクリーンショットに加えて
  # HTML とブラウザのコンソールログを残す。
  # CI はこのディレクトリをまるごと artifact として保存している。
  #
  # teardown ではセッションが既に破棄されており HTML が空になるため、
  # Rails がスクリーンショットを撮るのと同じ after_teardown で、
  # かつ super より前に実行する。
  def after_teardown
    save_failure_artifacts unless passed?
    super
  end

  # ブラウザのコンソールログはテストをまたいで溜まる。前のテストの記録が
  # 混ざって誤読したことがあるため、開始時に読み捨てる。
  setup { browser_console_logs }

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

  # CI でまれに、入力した値が反映されないまま空のフォームが残ることがある
  # （画面は差し替わっておらず JS エラーも出ない。原因は未特定）。
  #
  # 2回打ち直しても駄目なら JS で値を設定して続行する。入力はテストの
  # 本題ではなく、検証したいのは送信後の挙動（遷移・Turbo Stream・
  # バリデーション）であるため。送信自体は実際のクリックで行う。
  def fill_in_and_submit(button, fields)
    2.times do
      fields.each { |name, value| fill_in name.to_s, with: value }
      break if fields_filled?(fields)
    end

    unless fields_filled?(fields)
      warn "[system test] 「#{button}」のフォーム入力が反映されなかったため JS で設定した"
      fields.each { |name, value| set_field_by_script(name.to_s, value.to_s) }

      assert fields_filled?(fields), <<~MSG
        入力が保持されない（JS での設定も失敗）。
        ページが差し替わった形跡: #{page_replaced? ? "あり" : "なし"}
        現在の URL: #{page.current_url}
      MSG
    end

    click_button button
  end

  # date フィールドに Date を渡した場合も比較できるよう文字列に揃える
  def fields_filled?(fields)
    fields.all? { |name, value| page.has_field?(name.to_s, with: value.to_s, wait: 1) }
  end

  def set_field_by_script(name, value)
    page.execute_script(<<~JS, name, value)
      const el = document.getElementById(arguments[0]) ||
                 document.getElementsByName(arguments[0])[0];
      if (el) {
        el.value = arguments[1];
        el.dispatchEvent(new Event("input", { bubbles: true }));
        el.dispatchEvent(new Event("change", { bubbles: true }));
      }
    JS
  end

  # ページが差し替えられたかを判定するための目印。
  #
  # window に置くと、Turbo が <body> を差し替えても window は生き残るため
  # フルリロードしか検出できない（実際にそれで誤った診断をした）。
  # DOM 側に置いて、body の差し替えも検出できるようにする。
  def mark_page
    page.execute_script("document.body.dataset.testMark = '1'")
  end

  def page_replaced?
    page.evaluate_script("document.body.dataset.testMark") != "1"
  end

  def save_failure_artifacts
    dir = Rails.root.join("tmp/screenshots")
    FileUtils.mkdir_p(dir)
    base = dir.join("failures_#{method_name}")

    File.write("#{base}.html", page.html)
    logs = browser_console_logs
    File.write("#{base}.console.log", logs.join("\n")) if logs.any?
  rescue StandardError => e
    # ブラウザが落ちている場合などは取得できない。テストの失敗を隠さない。
    warn "失敗時の情報を保存できなかった: #{e.class}: #{e.message}"
  end

  def browser_console_logs
    page.driver.browser.logs.get(:browser).map(&:to_s)
  rescue StandardError => e
    [ "コンソールログの取得に失敗: #{e.class}" ]
  end

  # ページが操作可能になるまで待つ。
  #
  # Turbo Drive は再訪時にキャッシュのプレビューを先に描画し、その後で
  # 本来のレスポンスに差し替える。プレビューに対して入力やクリックを行うと、
  # 差し替えで入力値が消え、要素が切り離されてクリックが失われる。
  # プレビュー表示中は <html> に data-turbo-preview が付くので、それが
  # 外れるまで待つ。
  def wait_for_turbo
    Timeout.timeout(Capybara.default_max_wait_time) do
      until page.evaluate_script("document.readyState") == "complete" &&
            page.evaluate_script("typeof window.Turbo !== 'undefined'") &&
            !page.evaluate_script("document.documentElement.hasAttribute('data-turbo-preview')")
        sleep 0.05
      end
    end

    # 待ち終えた時点で目印を置く。失敗時の HTML に data-test-mark が
    # 残っていなければ、その後に body が差し替わったと分かる。
    mark_page
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
