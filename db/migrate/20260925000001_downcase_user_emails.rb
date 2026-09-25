class DowncaseUserEmails < ActiveRecord::Migration[7.2]
  # 既存の email を小文字に揃える。以降は User#normalize_email が正規化する。
  def up
    execute "UPDATE users SET email = lower(email) WHERE email <> lower(email)"
  end

  # 元の大文字小文字は復元できないため、巻き戻しは何もしない。
  def down
  end
end
