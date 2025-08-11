module Mutations
  class UpdateUser < GraphQL::Schema::Mutation
    null false
    argument :input, Types::UpdateUserInput, required: true

    field :user, Types::UserType, null: true
    field :errors, [String], null: false

    def resolve(input:)
      user = context[:current_user]
      return { user: nil, errors: ['Not authenticated'] } unless user

      attrs = input.to_h.transform_keys(&:to_s)

      # Your existing photo handling code here...

      # Extract photos and photo-related data as you have already
      photos = attrs.delete("photos")
      primary_index = attrs.delete("primary_photo_index")
      removed_indexes = attrs.delete("removed_photo_indexes")

      # Existing photo processing code here (backup, purge, attach)...

      # Now handle user attributes (including email & password)
      assign_attrs = {}
      assign_attrs[:first_name] = attrs["first_name"] if attrs["first_name"]
      assign_attrs[:last_name] = attrs["last_name"] if attrs["last_name"]
      assign_attrs[:mobile_number] = attrs["mobile_number"] if attrs["mobile_number"]
      assign_attrs[:birthdate] = attrs["birthdate"] if attrs["birthdate"]
      assign_attrs[:gender] = attrs["gender"] if attrs["gender"]
      assign_attrs[:sexual_orientation] = attrs["sexual_orientation"] if attrs["sexual_orientation"]
      assign_attrs[:gender_interest] = attrs["gender_interest"] if attrs["gender_interest"]
      assign_attrs[:country] = attrs["country"] if attrs["country"]
      assign_attrs[:state] = attrs["state"] if attrs["state"]
      assign_attrs[:city] = attrs["city"] if attrs["city"]
      assign_attrs[:school] = attrs["school"] if attrs["school"]
      assign_attrs[:bio] = attrs["bio"] if attrs["bio"]
      assign_attrs[:email] = attrs["email"] if attrs["email"].present?

      # Assign non-password attributes first
      user.assign_attributes(assign_attrs)

      # Validate password presence and length if provided
      if attrs["password"].present?
        user.password = attrs["password"]
      end

      # Perform validation and save
      if user.valid? && user.save
        { user: user, errors: [] }
      else
        # Collect validation errors including password/email errors
        { user: nil, errors: user.errors.full_messages }
      end
    rescue => e
      Rails.logger.error("[GraphQL::UpdateUser] #{e.class} #{e.message}\n#{e.backtrace.first(10).join("\n")}")
      { user: nil, errors: ["Internal server error"] }
    end
  end
end
