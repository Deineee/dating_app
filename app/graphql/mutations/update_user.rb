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

      photos = attrs.delete("photos")
      primary_index = attrs.delete("primary_photo_index")
      removed_indexes = attrs.delete("removed_photo_indexes")

      # Normalize removed indexes to array of unique integers sorted
      removed_idxs = Array(removed_indexes).map(&:to_i).uniq.sort

      # Existing attachments and blobs
      existing_attachments = user.photos.attachments.to_a
      existing_blobs = user.photos.blobs.to_a

      # Prepare blobs to keep (those not removed)
      blobs_to_keep = existing_blobs.each_with_index.reject { |_, idx| removed_idxs.include?(idx) }.map(&:first)

      # Download blobs to memory **before** purging old attachments
      backup = blobs_to_keep.map do |blob|
        {
          io: StringIO.new(blob.download),
          filename: blob.filename.to_s,
          content_type: blob.content_type
        }
      end

      # Attach new photos from base64 strings (append to backup)
      if photos.present? && photos.any? { |s| s.to_s.start_with?('data:') }
        photos.each_with_index do |data_url, idx|
          next unless data_url =~ /^data:(.*?);base64,/

          content_type = $1
          blob_data = data_url.split(',', 2).last
          decoded = Base64.decode64(blob_data)

          filename = "profile_photo_#{Time.now.to_i}_new_#{idx}.jpg"
          io = StringIO.new(decoded)

          backup << { io: io, filename: filename, content_type: content_type }
        end
      end

      # Apply primary index reorder on backup array
      if primary_index.present? && primary_index >= 0 && primary_index < backup.length
        chosen = backup.delete_at(primary_index)
        backup.unshift(chosen)
      end

      # Purge all existing attachments AFTER backing up
      existing_attachments.each(&:purge)

      # Attach all photos (kept + new + reordered)
      backup.each do |item|
        user.photos.attach(io: item[:io], filename: item[:filename], content_type: item[:content_type])
      end

      # Now apply other user attributes
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
