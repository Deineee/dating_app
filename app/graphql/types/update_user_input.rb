module Types
  class UpdateUserInput < Types::BaseInputObject
    description "Attributes for updating a user"   
    argument :first_name, String, required: false
    argument :last_name, String, required: false
    argument :mobile_number, String, required: false
    argument :birthdate, GraphQL::Types::ISO8601Date, required: false
    argument :gender, String, required: false
    argument :sexual_orientation, String, required: false
    argument :gender_interest, String, required: false
    argument :country, String, required: false
    argument :state, String, required: false
    argument :city, String, required: false
    argument :school, String, required: false
    argument :bio, String, required: false

    argument :photos, [String], required: false
    argument :primary_photo_index, Integer, required: false
    argument :removed_photo_indexes, [Integer], required: false
    
    argument :email, String, required: false
    argument :password, String, required: false
  end
end
