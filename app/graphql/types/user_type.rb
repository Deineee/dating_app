# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :email, String, null: false
    field :encrypted_password, String, null: false
    field :reset_password_token, String
    field :reset_password_sent_at, GraphQL::Types::ISO8601DateTime
    field :remember_created_at, GraphQL::Types::ISO8601DateTime
    field :first_name, String
    field :last_name, String
    field :mobile_number, String
    field :birthdate, GraphQL::Types::ISO8601Date
    field :gender, String
    field :sexual_orientation, String
    field :gender_interest, String
    field :country, String
    field :state, String
    field :city, String
    field :school, String
    field :bio, String
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :primary_photo, String, null: true

    def primary_photo
      object.photos.attached? ? Rails.application.routes.url_helpers.url_for(object.photos.first) : nil
    end
  end
end
