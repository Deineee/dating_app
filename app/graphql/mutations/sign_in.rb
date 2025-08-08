module Mutations
  class SignIn < BaseMutation
    argument :email, String, required: true
    argument :password, String, required: true

    field :user, Types::UserType, null: true
    field :token, String, null: true
    field :errors, [String], null: false

    def resolve(email:, password:)
      user = User.find_for_authentication(email:)
      if user&.valid_password?(password)
        token = user.generate_jwt # we’ll make this method in the model
        { user:, token:, errors: [] }
      else
        { user: nil, token: nil, errors: ["Invalid email or password"] }
      end
    end
  end
end
