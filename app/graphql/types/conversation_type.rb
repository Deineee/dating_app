module Types
  class ConversationType < Types::BaseObject
    field :user, Types::UserType, null: false
    field :last_message, Types::MessageType, null: true
    field :unread_count, Integer, null: false
  end
end
