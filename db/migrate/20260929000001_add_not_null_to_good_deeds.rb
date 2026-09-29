class AddNotNullToGoodDeeds < ActiveRecord::Migration[7.2]
  # モデル側では presence / numericality を検証済みだが DB 側が NULL 許容のままで、
  # update_column や直接 SQL などバリデーションを迂回する経路で NULL が入りうる状態だった。
  # 適用前に本番・開発ともに該当行が 0 件であることを確認済み。
  def change
    change_column_null :good_deeds, :content, false
    change_column_null :good_deeds, :performed_on, false
    change_column_null :good_deeds, :points, false
  end
end
