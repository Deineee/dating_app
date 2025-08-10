# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :sign_up, mutation: Mutations::SignUp
    field :sign_in, mutation: Mutations::SignIn
    field :sign_out, mutation: Mutations::SignOut
    field :like_user, mutation: Mutations::LikeUser
    field :dislike_user, mutation: Mutations::DislikeUser
    field :send_message, mutation: Mutations::SendMessage
    field :update_user, mutation: Mutations::UpdateUser
    field :mark_conversation_read, mutation: Mutations::MarkConversationRead
  end
end
