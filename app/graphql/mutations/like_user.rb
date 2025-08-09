module Mutations
  class LikeUser < BaseMutation
    argument :user_id, ID, required: true
    field :success, Boolean, null: false

    def resolve(user_id:)
      current_user = context[:current_user]
      return { success: false } unless current_user

      # Example: create a Like record (adjust per your models)
      Like.create!(liker_id: current_user.id, liked_id: user_id)
      { success: true }
    end
  end
end