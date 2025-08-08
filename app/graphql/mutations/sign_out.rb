module Mutations
  class SignOut < BaseMutation
    type Boolean

    def resolve
      context[:current_user] = nil
      true
    end
  end
end
