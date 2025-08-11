# db/seeds.rb
require "open-uri"

CLOUDINARY_URL = "https://res.cloudinary.com/dt53bls5a/image/upload/v1754905921/2osnzobnkhlhglm8tmk0q0y4uxb0.jpg"

admin = User.find_or_initialize_by(email: "admin@example.com")

admin.assign_attributes(
  first_name: "Admin",
  last_name: "User",
  mobile_number: "09171234567",
  birthdate: Date.new(1990,1,1),
  gender: "Male",
  sexual_orientation: "Female",
  gender_interest: "Female",
  country: "Philippines",
  state: "Metro Manila",
  city: "Manila",
  school: "Admin School",
  bio: "I am the admin user.",
  role: "admin"
)

# set password
admin.password = "password123"
admin.password_confirmation = "password123"

# If the user is new (not persisted), save without validations so we can attach ActiveStorage files.
# We skip validations only for the initial save because your model requires photos on validation.
if admin.new_record?
  admin.save!(validate: false)
end

# Attach the Cloudinary image if not already attached
unless admin.photos.attached?
  begin
    io = URI.open(CLOUDINARY_URL)
    admin.photos.attach(io: io, filename: "admin_primary.jpg", content_type: io.content_type)
    puts "Attached photo to admin from Cloudinary"
  rescue => e
    puts "Failed to attach remote image: #{e.message}"
  end
end

# Set primary_photo string column if you use it
admin.primary_photo = CLOUDINARY_URL

# Now run full validations/save — this should pass because photos are attached
admin.save!
puts "Admin user ready: #{admin.email} (id: #{admin.id})"

