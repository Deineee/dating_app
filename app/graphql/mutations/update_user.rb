module Mutations
  class UpdateUser < GraphQL::Schema::Mutation
    null false

    argument :id, ID, required: false
    argument :input, Types::UpdateUserInput, required: true

    field :user, Types::UserType, null: true
    field :errors, [String], null: false

    def resolve(id: nil, input:)
      current_user = context[:current_user]
      return { user: nil, errors: ['Not authenticated'] } unless current_user

      # Admin may update any user by passing id
      target =
        if id.present?
          return { user: nil, errors: ['Not authorized'] } unless current_user.role == 'admin'
          User.find_by(id: id)
        else
          current_user
        end

      return { user: nil, errors: ['User not found'] } unless target

      attrs = input.to_h.transform_keys(&:to_s)

      # Extract photos and photo-related data (your existing photo logic goes here if needed)
      photos = attrs.delete("photos")
      primary_index = attrs.delete("primary_photo_index")
      removed_indexes = attrs.delete("removed_photo_indexes")

      # example: assign permitted attrs (list out fields you want to allow)
      assign_attrs = {}
      %w[first_name last_name mobile_number birthdate gender sexual_orientation gender_interest country state city school bio email].each do |k|
        assign_attrs[k] = attrs[k] if attrs.key?(k)
      end

      target.assign_attributes(assign_attrs)

      if attrs["password"].present?
        target.password = attrs["password"]
      end

      if target.valid? && target.save
        # handle photos if you have logic: attach/purge/assign primary etc...
        { user: target, errors: [] }
      else
        { user: nil, errors: target.errors.full_messages }
      end
    rescue => e
      Rails.logger.error("[GraphQL::UpdateUser] #{e.class} #{e.message}\n#{e.backtrace.first(10).join("\n")}")
      { user: nil, errors: ["Internal server error"] }
    end
  end
end
