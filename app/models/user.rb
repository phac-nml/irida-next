# frozen_string_literal: true

# entity class for User
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :omniauthable

  has_one :namespace,
          class_name: 'Namespaces::UserNamespace',
          dependent: :destroy,
          foreign_key: :owner_id,
          inverse_of: :owner,
          autosave: true

  has_many :personal_access_tokens, dependent: :destroy

  before_validation :ensure_namespace
  before_save :ensure_namespace

  delegate :full_path, to: :namespace

  def self.from_omniauth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
      Rails.logger.debug '*********something in models/user.rb'
      Rails.logger.debug auth.info
      user.email = auth.uid
      user.password = Devise.friendly_token[0, 20]
      # user.name = auth.info.name   # assuming the user model has a name
      # user.image = auth.info.image # assuming the user model has an image
      # If you are using confirmable and the provider(s) you use validate emails,
      # uncomment the line below to skip the confirmation emails.
      # user.skip_confirmation!
    end
  end
  # def self.new_with_session(params, session)
  #   super.tap do |user|
  #     if data = session["devise.saml_data"] && session["devise.saml_data"]["extra"]["raw_info"]
  #       user.email = data["email"] if user.email.blank?
  #     end
  #   end
  # end

  # def self.from_omniauth(auth)
  #   # I don't think this is secure, or is correct in any way, but it lets me sign in
  #   user = User.find_by('email = ?', auth['info']['email'])
  #   if user.blank?
  #     user = User.new(
  #       {
  #         provider: auth.provider,
  #         uid: auth.uid,
  #         email: auth.info.email,
  #         password: Devise.friendly_token[0, 20]
  #       }
  #     )
  #     user.save!
  #   end
  #   user
  # end

  def update_password_with_password(params)
    current_password = params.delete(:current_password)

    result = if valid_password?(current_password)
               update(params)
             else
               assign_attributes(params)
               valid?
               errors.add(:current_password, current_password.blank? ? :blank : :invalid)
               false
             end

    clean_up_passwords
    result
  end

  def to_param
    full_path
  end

  private

  def build_namespace_name
    email
  end

  def build_namespace_path
    format('%<email>s', email:).sub! '@', '_at_'
  end

  def ensure_namespace
    if namespace
      namespace.path = build_namespace_path
      namespace.name = build_namespace_name
    else
      build_namespace(name: build_namespace_name, path: build_namespace_path)
    end
  end
end
