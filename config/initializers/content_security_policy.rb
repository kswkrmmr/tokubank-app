# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.object_src  :none
    policy.frame_ancestors :none
    policy.form_action :self

    # JS は app/assets/builds にバンドル済みのものだけを読み込む
    policy.script_src :self

    # レイアウトが Google Fonts のスタイルシートを読み込んでいる
    policy.style_src :self, "https://fonts.googleapis.com"
    policy.font_src  :self, "https://fonts.gstatic.com"

    # Bootstrap の JS が開閉アニメーションで style 属性を書き換えるため、
    # 属性に限って inline を許可する。<style> 要素は nonce で許可するので
    # ここを緩めても <style> の注入は防げる。
    policy.style_src_attr :unsafe_inline

    # Bootstrap の CSS がアイコンを data: URI で埋め込んでいる
    # （ハンバーガーメニューのアイコンなど）
    policy.img_src :self, :data

    # Turbo のフォーム送信・Turbo Stream のリクエスト
    policy.connect_src :self
  end

  # Turbo がプログレスバー用に差し込む <style> に nonce を付けるため。
  # レイアウトの csp_meta_tag が nonce を meta に出し、Turbo がそれを読む。
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[ script-src style-src ]
end
