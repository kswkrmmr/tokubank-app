require "test_helper"

class UserSessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "should get new" do
    get login_path
    assert_response :success
  end

  test "logs in with correct credentials" do
    post login_path, params: { email: @user.email, password: "password" }

    assert_redirected_to good_deeds_path
    follow_redirect!
    assert_response :success
  end

  test "logs in regardless of the case used in the email" do
    post login_path, params: { email: @user.email.upcase, password: "password" }

    assert_redirected_to good_deeds_path
  end

  test "logs in when the email has surrounding whitespace" do
    post login_path, params: { email: "  #{@user.email}  ", password: "password" }

    assert_redirected_to good_deeds_path
  end

  test "rejects a wrong password" do
    post login_path, params: { email: @user.email, password: "wrongpassword" }

    assert_response :unprocessable_entity
  end

  test "rejects an unknown email" do
    post login_path, params: { email: "nobody@example.com", password: "password" }

    assert_response :unprocessable_entity
  end

  test "rejects a blank email without raising" do
    post login_path, params: { email: "", password: "password" }

    assert_response :unprocessable_entity
  end

  test "logs out" do
    log_in_as(@user)
    delete logout_path

    assert_redirected_to root_path
    get good_deeds_path
    assert_redirected_to login_path
  end
end
