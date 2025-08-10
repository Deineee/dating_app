# app/graphql/resolvers/matches_resolver.rb
module Resolvers
  class MatchesResolver < GraphQL::Schema::Resolver
    description "Users that have mutually liked the current user (matches)"

    type [Types::UserType], null: false

    def resolve
      user = context[:current_user]
      return [] unless user

      # 1) Find IDs this user has liked
      liked_ids = Like.where(liker_id: user.id).pluck(:liked_id)
      return [] if liked_ids.empty?

      # 2) Find which of those users liked this user back (mutual)
      #    We get liker_id from records where liked_id == user.id and liker_id IN liked_ids
      mutual_ids = Like.where(liker_id: liked_ids, liked_id: user.id).pluck(:liker_id)

      return [] if mutual_ids.empty?

      # 3) Return the User records — limit/ordering optional
      User.where(id: mutual_ids)
          .select(:id, :first_name, :last_name, :primary_photo) # only necessary fields
          .order(updated_at: :desc)
    end
  end
end
