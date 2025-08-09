module Mutations
  class DislikeUser < BaseMutation
    argument :user_id, ID, required: true
        field :success, Boolean, null: false

        def resolve(user_id:)
        current_user = context[:current_user]
        return { success: false } unless current_user

        # You can record dislike if you want
        Dislike.create!(disliker_id: current_user.id, disliked_id: user_id)
        { success: true }
        end
    end
end