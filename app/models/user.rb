class User < ApplicationRecord
  has_secure_password

  validates :password, length: { minimum: 3 }, if: -> { new_record? || changes[:password_digest] }
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, uniqueness: true
end
