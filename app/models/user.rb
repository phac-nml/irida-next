# frozen_string_literal: true

# entity class for User
class User < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include HasUserType

  attr_accessor :skip_password_validation

  has_logidze
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

  acts_as_paranoid

  has_many :personal_access_tokens, dependent: :destroy
  has_many :data_exports, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :locale, inclusion: I18n.available_locales.map(&:to_s)

  # Groups
  has_many :members, inverse_of: :user, dependent: :destroy
  has_many :groups, through: :members

  before_validation :ensure_namespace
  before_save :ensure_namespace

  delegate :full_path, to: :namespace

  def self.ransackable_attributes(_auth_object = nil)
    %w[first_name last_name email]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  def self.from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)
    user.email = auth.info.email
    user.password = Devise.friendly_token[0, 20] if user.password.blank?

    # provider specific attributes are configured here
    case auth.provider
    when 'developer'
      user = from_developer(user, auth)
    when 'saml'
      user = from_saml(user, auth)
    when 'azure_activedirectory_v2'
      user = from_azure_activedirectory_v2(user, auth)
    end

    user.save
    user
  end

  def self.from_developer(user, auth)
    user.first_name = auth.info.first_name
    user.last_name = auth.info.last_name
    user
  end

  def self.from_saml(user, auth)
    user.first_name = auth.info.first_name
    user.last_name = auth.info.last_name
    user
  end

  def self.from_azure_activedirectory_v2(user, auth)
    user.first_name = auth.info.first_name
    user.last_name = auth.info.last_name
    user
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

  def username
    email.rpartition('@').first
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def build_namespace_name
    email
  end

  def build_namespace_path
    format('%<email>s', email:).sub! '@', '_at_'
  end

  def ensure_namespace
    return unless human?

    if namespace
      namespace.path = build_namespace_path
      namespace.name = build_namespace_name
    else
      build_namespace(name: build_namespace_name, path: build_namespace_path)
    end
  end

  def password_required?
    return false if skip_password_validation

    super
  end
end
