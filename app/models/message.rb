class Message < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :receiver, class_name: 'User'
  has_many :messages_sent, class_name: 'Message', foreign_key: :sender_id, dependent: :destroy
  has_many :messages_received, class_name: 'Message', foreign_key: :receiver_id, dependent: :destroy
  validates :content, presence: true

  scope :between, ->(a_id, b_id) {
    where("(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
          a_id, b_id, b_id, a_id).order(created_at: :asc)
  }

  scope :latest_for_user, ->(user_id) {
    # returns messages that are most recent grouped by conversation partner
    select("DISTINCT ON (LEAST(sender_id, receiver_id), GREATEST(sender_id, receiver_id)) *")
      .where("sender_id = :id OR receiver_id = :id", id: user_id)
      .order("LEAST(sender_id, receiver_id), GREATEST(sender_id, receiver_id), created_at DESC")
  }
end
