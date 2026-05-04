require "test_helper"

class GoodDeedsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get good_deeds_new_url
    assert_response :success
  end

  test "should get create" do
    get good_deeds_create_url
    assert_response :success
  end
end
