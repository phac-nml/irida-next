# frozen_string_literal: true

# entity class for User
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :namespace,
          class_name: 'Namespaces::UserNamespace',
          dependent: :destroy,
          foreign_key: :owner_id,
          inverse_of: :owner,
          autosave: true

  before_validation :ensure_namespace
  before_save :ensure_namespace

  # rubocop:disable Metrics/MethodLength
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
