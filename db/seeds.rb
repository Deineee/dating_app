# db/seeds.rb

User.create!(
  email: "admin@example.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Admin",
  last_name: "User",
  mobile_number: "0987654321",
  birthdate: Date.new(1990, 1, 1),
  gender: "Male",
  sexual_orientation: "Male",
  gender_interest: "Female",
  country: "Philippines",
  state: "Metro Manila",
  city: "Manila",
  school: "Admin School",
  bio: "I am the admin user.",
  role: "admin",
  primary_photo: "https://res.cloudinary.com/dt53bls5a/image/upload/v1754905921/2osnzobnkhlhglm8tmk0q0y4uxb0.jpg"
)
