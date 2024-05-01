# frozen_string_literal: true

# entity class for NamespaceBot
class NamespaceBot < ApplicationRecord
  has_logidze
  acts_as_paranoid

  after_destroy :remove_membership_from_namespace

  belongs_to :user, class_name: 'User'
  belongs_to :namespace, class_name: 'Namespace'

  validates :user_id, uniqueness: { scope: [:namespace_id] }

  validate :validate_bot_user_type

  def validate_bot_user_type
    return unless user.human?

    errors.add(:base, 'Human user cannot be set as a bot user for a namespace')
  end

  def membership
    user.members.find_by(namespace:)
  end

  def remove_membership_from_namespace
    user.members.find_by(namespace:)&.destroy
  end
end
