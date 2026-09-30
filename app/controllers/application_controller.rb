class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :logged_in?, :current_user
  before_action :require_login

  add_flash_types :success, :danger

  private

  # public にするとすべてのコントローラの public メソッド、
  # つまり潜在的なアクションになるため private に置く。
  # ビューからは helper_method 経由で参照する。
  def logged_in?
    !!current_user
  end

  def logout
    session[:user_id] = nil
    @current_user = nil
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_login
    redirect_to login_path, danger: t("defaults.flash_message.require_login") unless logged_in?
  end
end
