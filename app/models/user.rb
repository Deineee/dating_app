require 'jwt'

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many_attached :photos
  validates :first_name, :last_name, :mobile_number, :birthdate,
            :gender, :sexual_orientation, :gender_interest, :bio,
            presence: true

  validates :photos, attached: true
  validate :photos_count_within_limit
  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :mobile_number, format: { with: /\A[0-9]{10,15}\z/, message: "must be 10–15 digits" }
  validates :bio, length: { maximum: 500 }
  validates :role, presence: false, inclusion: { in: %w[user admin] }

  after_initialize :set_default_role, if: :new_record?

  def set_default_role
    self.role ||= 'user'
  end

  def photos_count_within_limit
    if photos.attached? && photos.count > 5
      errors.add(:photos, "cannot have more than 5")
    elsif photos.attached? && photos.count < 1
      errors.add(:photos, "must have at least 1 photo")
    end
  end
  
  def generate_jwt
    JWT.encode({ id: id, exp: 60.days.from_now.to_i }, Rails.application.secret_key_base)
  end

  def matched_user_ids
    liked_ids = Like.where(liker_id: id).pluck(:liked_id)
    return [] if liked_ids.empty?
    Like.where(liker_id: liked_ids, liked_id: id).pluck(:liker_id)
  end

  def matched_with?(other_user_id)
    matched_user_ids.include?(other_user_id)
  end
end
