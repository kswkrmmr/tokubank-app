require "test_helper"

class LikesControllerTest < ActionDispatch::IntegrationTest
  # Turbo Stream で返させるための Accept ヘッダ。
  # バグは create.turbo_stream.erb のレンダリング時に出るため、この経路で検証する。
  TURBO_STREAM = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  setup do
    @user = users(:one)
    @good_deed = good_deeds(:two) # 他ユーザーの徳
  end

  test "requires login" do
    post likes_path(good_deed_id: @good_deed.id)
    assert_redirected_to login_path
  end

  test "likes a deed" do
    log_in_as(@user)

    assert_difference "Like.count", 1 do
      post likes_path(good_deed_id: @good_deed.id), headers: TURBO_STREAM
    end
    assert_response :success
  end

  test "liking twice does not raise and keeps a single like" do
    log_in_as(@user)
    post likes_path(good_deed_id: @good_deed.id), headers: TURBO_STREAM
    assert_response :success

    assert_no_difference "Like.count" do
      post likes_path(good_deed_id: @good_deed.id), headers: TURBO_STREAM
    end
    assert_response :success
    assert_equal 1, @user.likes.where(good_deed: @good_deed).count
  end

  test "unlikes a deed" do
    log_in_as(@user)
    like = @user.likes.create!(good_deed: @good_deed)

    assert_difference "Like.count", -1 do
      delete like_path(like), headers: TURBO_STREAM
    end
    assert_response :success
  end

  test "unliking twice does not raise" do
    log_in_as(@user)
    like = @user.likes.create!(good_deed: @good_deed)
    delete like_path(like), headers: TURBO_STREAM

    assert_no_difference "Like.count" do
      delete like_path(like), headers: TURBO_STREAM
    end
    assert_response :redirect
  end

  test "cannot delete another user's like" do
    other_like = users(:two).likes.create!(good_deed: good_deeds(:one))
    log_in_as(@user)

    assert_no_difference "Like.count" do
      delete like_path(other_like), headers: TURBO_STREAM
    end
    assert_response :redirect
  end
end
