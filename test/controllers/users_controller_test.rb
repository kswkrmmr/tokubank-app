require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def valid_params(**overrides)
    { user: { name: "新規ユーザー", email: "new@example.com",
              password: "password", password_confirmation: "password" }.merge(overrides) }
  end

  test "should get new" do
    get new_user_path
    assert_response :success
  end

  test "creates a user and normalizes the email" do
    assert_difference "User.count", 1 do
      post users_path, params: valid_params(email: "  New.User@Example.COM  ")
    end

    assert_redirected_to root_path
    assert_equal "new.user@example.com", User.last.email
  end

  test "does not create a user when the confirmation does not match" do
    assert_no_difference "User.count" do
      post users_path, params: valid_params(password_confirmation: "different")
    end

    assert_response :unprocessable_entity
    assert_select "#error_explanation"
  end

  test "does not create a user when the email is already taken in a different case" do
    assert_no_difference "User.count" do
      post users_path, params: valid_params(email: users(:one).email.upcase)
    end

    assert_response :unprocessable_entity
  end

  test "does not create a user when the email format is invalid" do
    assert_no_difference "User.count" do
      post users_path, params: valid_params(email: "hoge")
    end

    assert_response :unprocessable_entity
  end

  test "does not create a user when the password is too short" do
    assert_no_difference "User.count" do
      post users_path, params: valid_params(password: "short", password_confirmation: "short")
    end

    assert_response :unprocessable_entity
  end
end
