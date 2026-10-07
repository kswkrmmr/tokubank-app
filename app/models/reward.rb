class Reward < ApplicationRecord
  MAX_COST = 100_000
  MAX_NAME_LENGTH = 255

  belongs_to :user

  validates :name, presence: true, length: { maximum: MAX_NAME_LENGTH }
  # 0pt のご褒美は意味がないので 1 以上。上限は integer の範囲を超えないため
  validates :cost, numericality: {
    only_integer: true,
    greater_than: 0,
    less_than_or_equal_to: MAX_COST
  }

  scope :pending, -> { where(redeemed_at: nil) }
  scope :redeemed, -> { where.not(redeemed_at: nil) }

  def redeemed?
    redeemed_at.present?
  end
end
