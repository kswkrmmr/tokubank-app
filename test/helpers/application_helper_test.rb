require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "maps flash types to existing bootstrap classes" do
    assert_equal "alert-success", flash_alert_class(:success)
    assert_equal "alert-danger", flash_alert_class(:danger)
    assert_equal "alert-danger", flash_alert_class("error")
    assert_equal "alert-warning", flash_alert_class(:alert)
    assert_equal "alert-info", flash_alert_class(:notice)
  end

  test "falls back to a neutral class for unknown types" do
    assert_equal "alert-secondary", flash_alert_class(:something_else)
  end
end
