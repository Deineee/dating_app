module Mutations
  class DislikeUser < BaseMutation
    argument :user_id, ID, required: true
    field :success, Boolean, null: false

    def resolve(user_id:)
      current_user = context[:current_user]
      return { success: false } unless current_user

      # Prevent disliking yourself
      return { success: false } if current_user.id == user_id.to_i

      # Check if Dislike already exists
      dislike = Dislike.find_by(disliker_id: current_user.id, disliked_id: user_id)
      return { success: true } if dislike.present?

      # Create Dislike record
      Dislike.create!(disliker_id: current_user.id, disliked_id: user_id)
      { success: true }
    rescue ActiveRecord::RecordInvalid => e
      { success: false }
    end
  end
end
