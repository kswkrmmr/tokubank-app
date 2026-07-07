require "test_helper"

class GoodDeedsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_good_deed_path
    assert_response :redirect
  end

  test "should get index" do
    get good_deeds_path
    assert_response :redirect
  end
end
