class GoodDeed < ApplicationRecord
  MAX_POINTS = 1_000
  MAX_CONTENT_LENGTH = 1_000

  belongs_to :user
  has_many :likes, dependent: :destroy

  validates :content, presence: true, length: { maximum: MAX_CONTENT_LENGTH }
  validates :performed_on, presence: true
  # 上限がないと integer の範囲を超えた値で ActiveRecord::RangeError になる。
  validates :points, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: MAX_POINTS
  }
end
