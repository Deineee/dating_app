module Mutations
  class LikeUser < BaseMutation
    argument :user_id, ID, required: true
    field :success, Boolean, null: false

    def resolve(user_id:)
      current_user = context[:current_user]
      return { success: false } unless current_user

      # Prevent liking yourself
      return { success: false } if current_user.id == user_id.to_i

      # Check if Like already exists to avoid duplicates
      like = Like.find_by(liker_id: current_user.id, liked_id: user_id)
      return { success: true } if like.present?

      # Create Like record
      Like.create!(liker_id: current_user.id, liked_id: user_id)
      { success: true }
    rescue ActiveRecord::RecordInvalid => e
      { success: false }
    end
  end
end
