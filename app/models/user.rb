class User < ApplicationRecord
  has_secure_password

  before_validation :normalize_email

  # presence / confirmation / 72バイト上限は has_secure_password が検証する。
  # ここは長さのみ。パスワード未指定の更新では nil になるため allow_nil。
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true,
                    uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  has_many :good_deeds, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :rewards, dependent: :destroy

  def own?(object)
    id == object&.user_id
  end

  # 積んだ徳の合計
  def total_points
    good_deeds.sum(:points)
  end

  # 叶えたご褒美で使った合計
  def spent_points
    rewards.redeemed.sum(:cost)
  end

  # 使える残高。徳を削除すると負になることがある
  def available_points
    total_points - spent_points
  end

  private

  # email のユニークインデックスは大小文字を区別するため、保存前に正規化する。
  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
