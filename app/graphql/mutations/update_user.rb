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

      # Extract photos + primary index (if provided)
      photos = attrs.delete("photos")
      primary_index = attrs.delete("primary_photo_index")

      # If new photos provided (non-empty array), replace user's photos.
      if photos.present?
        # purge existing photos
        user.photos.purge_later if user.photos.attached?

        # We want the chosen primary to be attached first.
        ordered = photos.dup
        if primary_index.present? && primary_index >= 0 && primary_index < photos.length
          chosen = ordered.delete_at(primary_index)
          ordered.unshift(chosen)
        end

        ordered.each_with_index do |data_url, idx|
          # Extract mime type & base64 data
          if data_url =~ /^data:(.*?);base64,/
            content_type = $1
            blob_data = data_url.split(',', 2).last
            decoded = Base64.decode64(blob_data)

            filename = "profile_photo_#{Time.now.to_i}_#{idx}.jpg"
            io = StringIO.new(decoded)
            # Attach - ActiveStorage will detect content_type
            user.photos.attach(io: io, filename: filename, content_type: content_type)
          else
            # if it's already a URL (not base64), skip — or you can handle remote fetch
            Rails.logger.info("[UpdateUser] photos input contains non-base64 entry, skipping")
          end
        end
      elsif photos && photos == [] && primary_index.present?
        # Case: user didn't upload new photos, but wants to reorder existing ones.
        # We'll re-order existing attachments so primary_index becomes first.
        if user.photos.attached?
          blobs = user.photos.blobs.to_a
          if primary_index >= 0 && primary_index < blobs.length
            # rotate blobs: make selected blob first
            chosen = blobs.delete_at(primary_index)
            new_order = [chosen] + blobs
            # re-attach in new order: easiest approach is to download each blob and re-attach
            # (This will create new blobs; for small amounts it is acceptable.)
            user.photos.purge
            new_order.each_with_index do |blob, idx|
              # blob.download returns bytes
              io = StringIO.new(blob.download)
              fname = blob.filename.to_s
              user.photos.attach(io: io, filename: fname, content_type: blob.content_type)
            end
          end
        end
      end

      # Now apply other attributes (snake_case keys should match your model)
      # Map GraphQL input keys to model attribute names if needed
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

      if user.update(assign_attrs)
        { user: user, errors: [] }
      else
        { user: nil, errors: user.errors.full_messages }
      end
    rescue => e
      Rails.logger.error("[GraphQL::UpdateUser] #{e.class} #{e.message}\n#{e.backtrace.first(10).join("\n")}")
      { user: nil, errors: ["Internal server error"] }
    end
  end
end
