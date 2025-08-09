module Mutations
  class SignUp < BaseMutation
    argument :first_name, String, required: true
    argument :last_name, String, required: true
    argument :mobile_number, String, required: true
    argument :email, String, required: true
    argument :password, String, required: true
    argument :password_confirmation, String, required: true
    argument :birthdate, GraphQL::Types::ISO8601Date, required: true
    argument :gender, String, required: true
    argument :sexual_orientation, String, required: true
    argument :gender_interest, String, required: true
    argument :country, String, required: false
    argument :state, String, required: false
    argument :city, String, required: false
    argument :school, String, required: false
    argument :bio, String, required: true
    argument :photos, [String], required: true 

    field :user, Types::UserType, null: true
    field :errors, [String], null: false

    def resolve(**args)
      photos_base64 = args.delete(:photos)
      user = User.new(args)

      if photos_base64.present?
        photos_base64.each_with_index do |base64_photo, index|
          decoded = Base64.decode64(base64_photo.split(",").last)
          filename = "photo_#{index}.jpg"

          user.photos.attach(
            io: StringIO.new(decoded),
            filename: filename,
            content_type: "image/jpeg"
          )
        end
      end

      if user.save
        # Set primary photo to first uploaded image URL
        if user.photos.attached?
          primary_url = user.photos.first.url # Provided by activestorage-cloudinary-service
          user.update_column(:primary_photo, primary_url)
        end

        { user: user, errors: [] }
      else
        { user: nil, errors: user.errors.full_messages }
      end
    end
  end
end
