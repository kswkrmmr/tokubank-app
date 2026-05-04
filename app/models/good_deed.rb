class GoodDeed < ApplicationRecord
  belongs_to :user

  validates :content, presence: true
  validates :performed_on, presence: true
  validates :points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end