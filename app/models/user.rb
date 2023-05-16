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

  # Groups
  has_many :members, inverse_of: :user, dependent: :destroy
  has_many :groups, through: :members

  before_validation :ensure_namespace
  before_save :ensure_namespace

  delegate :full_path, to: :namespace

  def self.from_omniauth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
      # # provider specific attributes can be configured here
      # case provider
      # when 'developer'
      #   user.name = auth.info.name
      # when 'saml'
      #   user.first_name = auth.info.first_name
      #   user.last_name = auth.info.last_name
      #   user.name = auth.info.name
      # when 'azure_activedirectory_v2'
      #   user.first_name = auth.info.first_name
      #   user.last_name = auth.info.last_name
      #   user.name = auth.info.name
      # end
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      # user.image = auth.info.image # assuming the user model has an image
      # If you are using confirmable and the provider(s) you use validate emails,
      # uncomment the line below to skip the confirmation emails.
      # user.skip_confirmation!
    end
  end

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
