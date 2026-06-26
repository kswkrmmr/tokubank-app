class Like < ApplicationRecord
  belongs_to :user
  belongs_to :good_deed

  validates :user_id, uniqueness: { scope: :good_deed_id }
end
