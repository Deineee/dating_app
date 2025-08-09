class Like < ApplicationRecord
  belongs_to :liker, class_name: "User"
  belongs_to :liked, class_name: "User"

  validates :liker_id, uniqueness: { scope: :liked_id }
  validate :cannot_like_self

  def cannot_like_self
    errors.add(:liker_id, "can't like yourself") if liker_id == liked_id
  end
end
