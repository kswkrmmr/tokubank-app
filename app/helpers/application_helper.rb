module ApplicationHelper
  # flash のキーをそのまま alert-#{key} にすると、add_flash_types で
  # 追加していない notice / alert が来たときに Bootstrap に存在しない
  # クラス（alert-notice / alert-alert）になり無色で表示されてしまう。
  FLASH_ALERT_CLASSES = {
    "success" => "alert-success",
    "danger" => "alert-danger",
    "error" => "alert-danger",
    "alert" => "alert-warning",
    "notice" => "alert-info"
  }.freeze

  def flash_alert_class(message_type)
    FLASH_ALERT_CLASSES.fetch(message_type.to_s, "alert-secondary")
  end
end
