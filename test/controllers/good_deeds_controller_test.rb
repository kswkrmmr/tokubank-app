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

  test "today points are counted in Asia/Tokyo even before 9:00 JST" do
    user = users(:one)
    user.good_deeds.create!(content: "朝の徳1", performed_on: Date.new(2026, 9, 11), points: 3)
    user.good_deeds.create!(content: "朝の徳2", performed_on: Date.new(2026, 9, 11), points: 4)

    # 2026-09-11 08:00 JST = 2026-09-10 23:00 UTC
    travel_to Time.zone.local(2026, 9, 11, 8, 0) do
      log_in_as(user)
      get good_deeds_path
    end

    assert_response :success
    assert_select "h2", text: "7 pt"
  end

  test "pagination does not duplicate or skip deeds sharing the same date" do
    user = users(:one)
    25.times { |i| user.good_deeds.create!(content: "同日の徳#{i}", performed_on: Date.new(2026, 5, 3), points: 1) }
    expected = user.good_deeds.pluck(:content)

    log_in_as(user)
    contents = [ 1, 2 ].flat_map do |page|
      get good_deeds_path(page: page)
      css_select(".card-body strong").map(&:text)
    end

    assert_equal expected.size, contents.size
    assert_equal expected.sort, contents.sort
  end
end
