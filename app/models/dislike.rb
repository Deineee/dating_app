class Dislike < ApplicationRecord
  belongs_to :disliker, class_name: "User"
  belongs_to :disliked, class_name: "User"

  validates :disliker_id, uniqueness: { scope: :disliked_id }
  validate :cannot_dislike_self

  def cannot_dislike_self
    errors.add(:disliker_id, "can't dislike yourself") if disliker_id == disliked_id
  end
end
