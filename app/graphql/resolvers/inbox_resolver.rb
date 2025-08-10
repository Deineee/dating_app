module Resolvers
  class InboxResolver < GraphQL::Schema::Resolver
    type [Types::ConversationType], null: false

    def resolve
      user = context[:current_user]
      return [] unless user

      # find latest message per conversation
      # we can use a union key: [LEAST(sender_id, receiver_id), GREATEST(...)]
      # Simpler approach: load messages involving user and group in ruby (ok for small scale)
      messages = Message.where("sender_id = :id OR receiver_id = :id", id: user.id)
                        .order(created_at: :desc)
      
      seen = {}
      conversations = []
      messages.each do |m|
        partner_id = (m.sender_id == user.id) ? m.receiver_id : m.sender_id
        next if seen[partner_id]
        seen[partner_id] = true

        partner = User.find_by(id: partner_id)
        next unless partner

        unread = Message.where(sender_id: partner_id, receiver_id: user.id, read_at: nil).count

        conversations << OpenStruct.new(user: partner, last_message: m, unread_count: unread)
      end

      conversations
    end
  end
end
