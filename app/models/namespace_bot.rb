# frozen_string_literal: true

# entity class for NamespaceBot
class NamespaceBot < ApplicationRecord
  has_logidze
  acts_as_paranoid

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
end
