module Resolvers
  class MatchingProfilesResolver
    def self.call(context)
      user = context[:current_user]
      return [] unless user

      liked_ids = Like.where(liker_id: user.id).pluck(:liked_id)
      disliked_ids = Dislike.where(disliker_id: user.id).pluck(:disliked_id)
      excluded_ids = liked_ids + disliked_ids + [user.id]

      User.where("LOWER(gender) = ?", user.gender_interest.downcase)
          .where.not(id: excluded_ids)
          .limit(20)
    end
  end
end
