module Resolvers
  class ConversationResolver < GraphQL::Schema::Resolver
    description "Messages between current_user and another user"
    type [Types::MessageType], null: false
    argument :user_id, ID, required: true

    def resolve(user_id:)
      user = context[:current_user]
      return [] unless user

      other_id = user_id.to_i

      # Only allow if matched
      return [] unless user.matched_with?(other_id)

      Message.between(user.id, other_id)
    end
  end
end
