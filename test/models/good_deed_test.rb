require "test_helper"

class GoodDeedTest < ActiveSupport::TestCase
  def build_deed(**attrs)
    users(:one).good_deeds.build({ content: "ゴミを拾った", performed_on: Date.new(2026, 5, 3), points: 1 }.merge(attrs))
  end

  test "valid deed" do
    assert build_deed.valid?
  end

  test "content is required" do
    assert_not build_deed(content: nil).valid?
    assert_not build_deed(content: "").valid?
  end

  test "content has a maximum length" do
    assert build_deed(content: "あ" * GoodDeed::MAX_CONTENT_LENGTH).valid?
    assert_not build_deed(content: "あ" * (GoodDeed::MAX_CONTENT_LENGTH + 1)).valid?
  end

  test "performed_on is required" do
    assert_not build_deed(performed_on: nil).valid?
  end

  test "points must be a number" do
    assert_not build_deed(points: nil).valid?
    assert_not build_deed(points: "abc").valid?
  end

  test "points must not be negative" do
    assert build_deed(points: 0).valid?
    assert_not build_deed(points: -1).valid?
  end

  test "points has an upper bound so it cannot overflow the integer column" do
    assert build_deed(points: GoodDeed::MAX_POINTS).valid?
    assert_not build_deed(points: GoodDeed::MAX_POINTS + 1).valid?
    assert_not build_deed(points: 2_147_483_648).valid?
  end

  test "user is required" do
    assert_not GoodDeed.new(content: "徳", performed_on: Date.new(2026, 5, 3), points: 1).valid?
  end

  test "destroying a deed destroys its likes" do
    deed = good_deeds(:one)
    users(:two).likes.create!(good_deed: deed)

    assert_difference "Like.count", -1 do
      deed.destroy
    end
  end

  # バリデーションを迂回する経路を DB 側で塞げているかの確認
  test "database rejects null values on required columns" do
    deed = good_deeds(:one)

    [ :content, :performed_on, :points ].each do |column|
      assert_raises ActiveRecord::NotNullViolation, "#{column} の NOT NULL 制約が効いていない" do
        # 制約違反でトランザクションが中断され、後続の検証ができなくなるため
        # セーブポイントを張って1件ずつ巻き戻す
        GoodDeed.transaction(requires_new: true) { deed.update_column(column, nil) }
      end
    end
  end
end
