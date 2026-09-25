require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(**attrs)
    User.new({ name: "テスト", email: "new@example.com", password: "password", password_confirmation: "password" }.merge(attrs))
  end

  test "valid user" do
    assert build_user.valid?
  end

  test "email is downcased and stripped before save" do
    user = build_user(email: "  New.User@Example.COM  ")
    assert user.save
    assert_equal "new.user@example.com", user.reload.email
  end

  test "email differing only in case is rejected as duplicate" do
    user = build_user(email: users(:one).email.upcase)

    assert_not user.valid?
    assert_includes user.errors.attribute_names, :email
  end

  test "email requires a valid format" do
    [ "hoge", "hoge@", "@example.com", "ho ge@example.com" ].each do |invalid|
      assert_not build_user(email: invalid).valid?, "#{invalid} が通ってしまう"
    end
  end

  test "email is required" do
    assert_not build_user(email: "").valid?
  end

  test "name is required" do
    assert_not build_user(name: "").valid?
  end

  test "password requires at least 8 characters" do
    assert_not build_user(password: "short1", password_confirmation: "short1").valid?
    assert build_user(password: "longenough", password_confirmation: "longenough").valid?
  end

  test "password is not validated when unchanged" do
    user = users(:one)
    user.name = "改名"

    assert user.valid?
  end

  test "own? tells whether the record belongs to the user" do
    assert users(:one).own?(good_deeds(:one))
    assert_not users(:one).own?(good_deeds(:two))
    assert_not users(:one).own?(nil)
  end
end
