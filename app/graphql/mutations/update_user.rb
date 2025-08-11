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

      # Determine target user
      target =
        if id.present?
          # Only admins can update other users
          return { user: nil, errors: ['Not authorized'] } unless current_user.role == 'admin'
          User.find_by(id: id)
        else
          current_user
        end

      return { user: nil, errors: ['User not found'] } unless target

      attrs = input.to_h.transform_keys(&:to_s)

      photos = attrs.delete("photos")
      primary_index = attrs.delete("primary_photo_index")
      removed_indexes = attrs.delete("removed_photo_indexes")

      # Handle photos ONLY if updating own profile (no id passed)
      if id.nil?
        # --- photo handling logic from profile page ---

        removed_idxs = Array(removed_indexes).map(&:to_i).uniq.sort

        existing_attachments = target.photos.attachments.to_a
        existing_blobs = target.photos.blobs.to_a

        blobs_to_keep = existing_blobs.each_with_index.reject { |_, idx| removed_idxs.include?(idx) }.map(&:first)

        backup = blobs_to_keep.map do |blob|
          {
            io: StringIO.new(blob.download),
            filename: blob.filename.to_s,
            content_type: blob.content_type
          }
        end

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

        if primary_index.present? && primary_index >= 0 && primary_index < backup.length
          chosen = backup.delete_at(primary_index)
          backup.unshift(chosen)
        end

        existing_attachments.each(&:purge)

        backup.each do |item|
          target.photos.attach(io: item[:io], filename: item[:filename], content_type: item[:content_type])
        end
      end

      # Prepare attributes to update (allow email & password only if admin)
      permitted_attrs = %w[first_name last_name mobile_number birthdate gender sexual_orientation gender_interest country state city school bio]
      permitted_attrs << 'email' if current_user.role == 'admin'
      
      assign_attrs = {}
      permitted_attrs.each do |k|
        assign_attrs[k] = attrs[k] if attrs.key?(k)
      end

      target.assign_attributes(assign_attrs)

      # Password update only allowed for admin updating other user or current user updating self with id nil
      if attrs["password"].present?
        # current_user can update own password, admin can update any user's password
        if (id.nil? && target == current_user) || (id.present? && current_user.role == 'admin')
          target.password = attrs["password"]
        else
          return { user: nil, errors: ['Not authorized to update password'] }
        end
      end

      if target.save
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
