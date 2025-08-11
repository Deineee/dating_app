module Types
  class QueryType < Types::BaseObject
    field :current_user, Types::UserType, null: true
    field :matching_profiles, [Types::UserType], null: false
    field :matches, resolver: Resolvers::MatchesResolver
    field :inbox, resolver: Resolvers::InboxResolver
    field :conversation, resolver: Resolvers::ConversationResolver
    field :all_users, [Types::UserType], null: false,
      description: "List all users (admin only)"
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    def current_user
      context[:current_user]
    end

    def matching_profiles
      Resolvers::MatchingProfilesResolver.call(context)
    end

    def all_users
      current_user = context[:current_user]
      return User.none unless current_user&.role == 'admin'
      User.all
    end

    field :user, Types::UserType, null: true do
      argument :id, ID, required: true
    end

    def user(id:)
      current_user = context[:current_user]
      return nil unless current_user&.role == 'admin'

      Rails.logger.info("[GraphQL] QueryType#user called with id=#{id.inspect}")

      # 1) If it's already a Rails GlobalID (starts with "gid://"), try GlobalID.find
      begin
        if id.is_a?(String) && id.start_with?('gid://')
          found = GlobalID.find(id) rescue nil
          Rails.logger.info("[GraphQL] tried GlobalID.find -> #{found&.class}##{found&.id}") if found
          return found if found.is_a?(User)
        end
      rescue => e
        Rails.logger.warn("[GraphQL] GlobalID.find error: #{e.class}: #{e.message}")
      end

      # 2) Try GraphQL-Ruby Relay decode (base64 style) -> ["User", "16"]
      begin
        if id.is_a?(String)
          type_name, item_id = GraphQL::Schema::UniqueWithinType.decode(id) rescue nil
          if type_name && item_id
            Rails.logger.info("[GraphQL] decode -> type=#{type_name}, id=#{item_id}")
            if type_name == "User"
              user = User.find_by(id: item_id)
              return user if user
            end
          end
        end
      rescue => e
        Rails.logger.warn("[GraphQL] Relay decode error: #{e.class}: #{e.message}")
      end

      # 3) Try schema.object_from_id (some projects implement custom logic there)
      begin
        obj = context.schema.object_from_id(id, context) rescue nil
        Rails.logger.info("[GraphQL] schema.object_from_id -> #{obj&.class}##{obj&.id}") if obj
        return obj if obj.is_a?(User)
      rescue => e
        Rails.logger.warn("[GraphQL] object_from_id error: #{e.class}: #{e.message}")
      end

      # 4) Last-ditch: attempt to treat id as raw DB id (integer or numeric string)
      begin
        return User.find_by(id: id)
      rescue => e
        Rails.logger.warn("[GraphQL] raw find_by(id) error: #{e.class}: #{e.message}")
        nil
      end
    end
  end
end
