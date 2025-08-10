module Mutations
  class MarkConversationRead < GraphQL::Schema::Mutation
    null false

    argument :user_id, ID, required: true

    field :marked_count, Integer, null: false

    def resolve(user_id:)
      user = context[:current_user]
      raise GraphQL::ExecutionError, "Not authenticated" unless user

      partner_id = user_id.to_i
      msgs = Message.where(sender_id: partner_id, receiver_id: user.id, read_at: nil)

      # update_all returns number of rows updated in AR 6+
      count = msgs.update_all(read_at: Time.current)
      { marked_count: count }
    end
  end
end
