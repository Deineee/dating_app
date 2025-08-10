module Mutations
  class SendMessage < BaseMutation
    argument :receiver_id, ID, required: true
    argument :content, String, required: true

    field :message, Types::MessageType, null: true
    field :errors, [String], null: false

    def resolve(receiver_id:, content:)
      user = context[:current_user]
      return { message: nil, errors: ['Not authenticated'] } unless user

      receiver = User.find_by(id: receiver_id)
      return { message: nil, errors: ['Receiver not found'] } unless receiver

      # ensure match
      unless user.matched_with?(receiver.id)
        return { message: nil, errors: ['Can only message matches'] }
      end

      msg = Message.create(sender: user, receiver: receiver, content: content)
      if msg.persisted?
        # optionally broadcast via ActionCable / GraphQL subscription here
        { message: msg, errors: [] }
      else
        { message: nil, errors: msg.errors.full_messages }
      end
    end
  end
end
